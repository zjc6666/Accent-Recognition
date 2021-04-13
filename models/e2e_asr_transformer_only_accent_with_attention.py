# Copyright 2019 Shigeki Karita
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

"""Transformer speech recognition model (pytorch)."""

from argparse import Namespace
import logging
import math

import numpy
import torch

from espnet.nets.asr_interface import ASRInterface
from espnet.nets.ctc_prefix_score import CTCPrefixScore
from espnet.nets.e2e_asr_common import end_detect
from espnet.nets.e2e_asr_common import ErrorCalculator
from espnet.nets.pytorch_backend.ctc import CTC
from espnet.nets.pytorch_backend.e2e_asr import CTC_LOSS_THRESHOLD
# from espnet.nets.pytorch_backend.e2e_asr import Reporter
from espnet.nets.pytorch_backend.nets_utils import get_subsample
from espnet.nets.pytorch_backend.nets_utils import make_non_pad_mask
from espnet.nets.pytorch_backend.nets_utils import th_accuracy
from espnet.nets.pytorch_backend.rnn.decoders import CTC_SCORING_RATIO
from espnet.nets.pytorch_backend.transformer.add_sos_eos import add_sos_eos
from espnet.nets.pytorch_backend.transformer.argument import (
    add_arguments_transformer_common,  # noqa: H301
)
from espnet.nets.pytorch_backend.transformer.attention import (
    MultiHeadedAttention,  # noqa: H301
    RelPositionMultiHeadedAttention,  # noqa: H301
)
from espnet.nets.pytorch_backend.transformer.decoder import Decoder
from espnet.nets.pytorch_backend.transformer.dynamic_conv import DynamicConvolution
from espnet.nets.pytorch_backend.transformer.dynamic_conv2d import DynamicConvolution2D
from espnet.nets.pytorch_backend.transformer.encoder import Encoder
from espnet.nets.pytorch_backend.transformer.initializer import initialize
from espnet.nets.pytorch_backend.transformer.label_smoothing_loss import (
    LabelSmoothingLoss,  # noqa: H301
)
from espnet.nets.pytorch_backend.transformer.mask import subsequent_mask
from espnet.nets.pytorch_backend.transformer.mask import target_mask
from espnet.nets.pytorch_backend.transformer.plot import PlotAttentionReport
from espnet.nets.scorers.ctc import CTCPrefixScorer
from espnet.utils.fill_missing_args import fill_missing_args
# add by zjc
import torch
import torch.nn as nn
import chainer
from chainer import reporter

class Reporter(chainer.Chain):
    """A chainer reporter wrapper."""

    def report(self, acc, loss):
        """Report at every step."""
        reporter.report({'acc': acc}, self)
        reporter.report({'loss': loss}, self)

def new_parameter(*size):
    out = torch.nn.Parameter(torch.FloatTensor(*size))
    torch.nn.init.xavier_normal(out)
    return out

## Just simple implementation from https://pytorch-nlp-tutorial-ny2018.readthedocs.io/en/latest/day2/patterns/attention.html
class Attention(nn.Module):
    def __init__(self, attention_size):
        super(Attention, self).__init__()
        self.attention = new_parameter(attention_size, 1)

    def forward(self, x_in):
        # after this, we have (batch, dim1) with a diff weight per each cell
        attention_score = torch.matmul(x_in, self.attention).squeeze()
        attention_score = torch.nn.functional.softmax(attention_score).view(x_in.size(0), x_in.size(1), 1)
        scored_x = x_in * attention_score

        # now, sum across dim 1 to get the expected feature vector
        condensed_x = torch.sum(scored_x, dim=1)

        return condensed_x


class E2E(ASRInterface, torch.nn.Module):
    """E2E module.

    :param int idim: dimension of inputs
    :param int odim: dimension of outputs
    :param Namespace args: argument Namespace containing options

    """

    @staticmethod
    def add_arguments(parser):
        """Add arguments."""
        group = parser.add_argument_group("transformer model setting")
        group.add_argument('--pretrained-model', default="", type=str,
                           help='pretrained ASR model for initialization')
        group.add_argument('--train-pkl', default="", type=str,
                           help='train pkl files')
        group.add_argument('--valid-pkl', default="", type=str,
                           help='valid pkl files')
        group.add_argument('--test-pkl', default="", type=str,
                          help='test pkl files')
        group.add_argument('--wav2vec-path', default="", type=str,
                           help='pre-trained wav2vec model')

        group = add_arguments_transformer_common(group)

        return parser

    @property
    def attention_plot_class(self):
        """Return PlotAttentionReport."""
        return PlotAttentionReport

    def get_total_subsampling_factor(self):
        """Get total subsampling factor."""
        return self.encoder.conv_subsampling_factor * int(numpy.prod(self.subsample))

    def __init__(self, idim, odim, args, ignore_id=-1):
        """Construct an E2E object.

        :param int idim: dimension of inputs
        :param int odim: dimension of outputs
        :param Namespace args: argument Namespace containing options
        """
        torch.nn.Module.__init__(self)

        # fill missing arguments for compatibility
        args = fill_missing_args(args, self.add_arguments)

        if args.transformer_attn_dropout_rate is None:
            args.transformer_attn_dropout_rate = args.dropout_rate
        self.encoder = Encoder(
            idim=idim,
            selfattention_layer_type=args.transformer_encoder_selfattn_layer_type,
            attention_dim=args.adim,
            attention_heads=args.aheads,
            conv_wshare=args.wshare,
            conv_kernel_length=args.ldconv_encoder_kernel_length,
            conv_usebias=args.ldconv_usebias,
            linear_units=args.eunits,
            num_blocks=args.elayers,
            input_layer=args.transformer_input_layer,
            dropout_rate=args.dropout_rate,
            positional_dropout_rate=args.dropout_rate,
            attention_dropout_rate=args.transformer_attn_dropout_rate,
        )
        odim = odim - 1
        self.odim = odim
        self.ignore_id = ignore_id
        self.subsample = get_subsample(args, mode="asr", arch="transformer")
        self.reporter = Reporter()

        self.criterion = LabelSmoothingLoss(self.odim, self.ignore_id, args.lsm_weight,
                                            args.transformer_length_normalized_loss)
        self.output = torch.nn.Linear(256, self.odim) # mean + std pooling
        self.att = Attention(256)

        self.reset_parameters(args)
        self.adim = args.adim  # used for CTC (equal to d_model)
    def reset_parameters(self, args):
        """Initialize parameters."""
        if args.pretrained_model:
            path = args.pretrained_model
            logging.warning("load pretrained asr model from {}".format(path))
            if 'snapshot' in path:
                model_state_dict = torch.load(path, map_location=lambda storage, loc: storage)['model']
            else:
                model_state_dict = torch.load(path, map_location=lambda storage, loc: storage)
            self.load_state_dict(model_state_dict, strict=False)
            del model_state_dict
        else:
            initialize(self, args.transformer_init)

    def forward(self, xs_pad, ilens, ys_pad):
        """E2E forward.

        :param torch.Tensor xs_pad: batch of padded source sequences (B, Tmax, idim)
        :param torch.Tensor ilens: batch of lengths of source sequences (B)
        :param torch.Tensor ys_pad: batch of padded target sequences (B, Lmax)
        :return: ctc loss value
        :rtype: torch.Tensor
        :return: attention loss value
        :rtype: torch.Tensor
        :return: accuracy in attention decoder
        :rtype: float
        """
        # 1. forward encoder
        xs_pad = xs_pad[:, : max(ilens)]  # for data parallel
        src_mask = make_non_pad_mask(ilens.tolist()).to(xs_pad.device).unsqueeze(-2)
        hs_pad, hs_mask = self.encoder(xs_pad, src_mask)
        self.hs_pad = hs_pad

        hs_mask = hs_mask.transpose(1,2)
        hs_mask = hs_mask.repeat(1,1,256).type(torch.FloatTensor).to(hs_pad.device)
        hs_pad_masked = hs_pad * hs_mask
        logging.warning("hs_pad_masked.size()==>" + str(hs_pad_masked.size()))
        att_vec = self.att(hs_pad_masked)

        # att_vec = self.att(hs_pad)

        pred_pad = self.output(att_vec).unsqueeze(1)
        logging.warning("att_vec.size()==>" + str(att_vec.size()))
        logging.warning("pred_pad.size()==>" + str(pred_pad.size()))
        # compute loss
        self.loss = self.criterion(pred_pad, ys_pad)
        self.acc = th_accuracy(pred_pad.view(-1, self.odim), ys_pad,
                               ignore_label=self.ignore_id)

        loss_data = float(self.loss)
        if loss_data < CTC_LOSS_THRESHOLD and not math.isnan(loss_data):
             self.reporter.report(self.acc, loss_data)
        else:
            logging.warning("loss (=%f) is not correct", loss_data)
        return self.loss

    def scorers(self):
        """Scorers."""
        return dict(decoder=self.decoder, ctc=CTCPrefixScorer(self.ctc, self.eos))

    def encode(self, x):
        """Encode acoustic features.

        :param ndarray x: source acoustic feature (T, D)
        :return: encoder outputs
        :rtype: torch.Tensor
        """
        self.eval()
        x = torch.as_tensor(x).unsqueeze(0)
        enc_output, _ = self.encoder(x, None)
        return enc_output.squeeze(0)

    def recognize(self, x, recog_args, char_list=None, rnnlm=None, use_jit=False):
        """Recognize input speech.

        :param ndnarray x: input acoustic feature (B, T, D) or (T, D)
        :param Namespace recog_args: argment Namespace contraining options
        :param list char_list: list of characters
        :param torch.nn.Module rnnlm: language model module
        :return: N-best decoding results
        :rtype: list
        """
        enc_output = self.encode(x).unsqueeze(0)
        att_vec = self.att(enc_output)
        
        lpz = self.output(att_vec)
        lpz = lpz.squeeze(0) # shape of (T, D)
        idx = lpz.argmax(-1).cpu().numpy().tolist()
        hyp = {}
        # [-1] is added here to be compatible with ASR decoding, see espnet/asr/asr_utils/parse_hypothesis
        hyp['yseq'] = [-1] + [idx]
        hyp['score'] = -1
        logging.info(hyp['yseq'])

        return [hyp]

    def calculate_all_attentions(self, xs_pad, ilens, ys_pad):
        """E2E attention calculation.

        :param torch.Tensor xs_pad: batch of padded input sequences (B, Tmax, idim)
        :param torch.Tensor ilens: batch of lengths of input sequences (B)
        :param torch.Tensor ys_pad: batch of padded token id sequence tensor (B, Lmax)
        :return: attention weights (B, H, Lmax, Tmax)
        :rtype: float ndarray
        """
        self.eval()
        with torch.no_grad():
            self.forward(xs_pad, ilens, ys_pad)
        ret = dict()
        for name, m in self.named_modules():
            if (
                isinstance(m, MultiHeadedAttention)
                or isinstance(m, DynamicConvolution)
                or isinstance(m, RelPositionMultiHeadedAttention)
            ):
                ret[name] = m.attn.cpu().numpy()
            if isinstance(m, DynamicConvolution2D):
                ret[name + "_time"] = m.attn_t.cpu().numpy()
                ret[name + "_freq"] = m.attn_f.cpu().numpy()
        self.train()
        return ret

    def calculate_all_ctc_probs(self, xs_pad, ilens, ys_pad):
        """E2E CTC probability calculation.

        :param torch.Tensor xs_pad: batch of padded input sequences (B, Tmax)
        :param torch.Tensor ilens: batch of lengths of input sequences (B)
        :param torch.Tensor ys_pad: batch of padded token id sequence tensor (B, Lmax)
        :return: CTC probability (B, Tmax, vocab)
        :rtype: float ndarray
        """
        ret = None
        if self.mtlalpha == 0:
            return ret

        self.eval()
        with torch.no_grad():
            self.forward(xs_pad, ilens, ys_pad)
        for name, m in self.named_modules():
            if isinstance(m, CTC) and m.probs is not None:
                ret = m.probs.cpu().numpy()
        self.train()
        return ret
