# Accent-Recognition

# Data preparation scripts and training pipeline for the Accented English Speech Recognition.

# Environment dependent
  1. Kaldi (Data preparation related function script) [Github link](https://github.com/kaldi-asr/kaldi)
  2. Espnet  [Githhub link](https://github.com/espnet/espnet)
  3. Google SentencePiece(pip3 install sentencepiece)  [Github link](https://github.com/google/sentencepiece)
  4. Modify the installation address of espnet in the path.sh file
  
# Instructions for use
## Data preparation
  1. All the data used in the experiment are stored in the `data` directory, in which train is used for training, valid is the verification set, 
    cv_all and test are used for testing respectively.
  2. In order to better reproduce my experimental results, you can download the data set first, and then directly change the path in `wav.scp` in different sets in `data` directory. You can also use the `sed` command to replace the path in the wav.scp file with your path.
  3. Other files can remain unchanged, you can use it directly (eg, utt2IntLabel, utt2accent, text, utt2spk...).

## Accent recognition system
  1. Model file preparation
    `run_accent.sh` is used to train a accent recognition model.
    Before running, you need to first put the model file(models/e2e_asr_transformer_accent.py) to your espnet directory.
```
eg: 
  move `models/e2e_asr_transformer_accent.py` to `/your espnet localtion/espnet/nets/pytorch_backend` 
  move `models/e2e_asr_transformer_accent_with_attention.py` to `/your espnet localtion/espnet/nets/pytorch_backend` 
```
  2. step by step
    The overall code is divided into four parts, including feature extraction, JSON file generation, model training and decoding. 
    The model training is divided into two parts, using ASR init(step05) and not using ASR init(step04). 
    You can control the steps by changing the value of the step variable. 

```
egs: 
  bash run_accent.sh --nj 20 --steps 1-2 data exp
  bash run_accent.sh --nj 20 --steps 3 data exp
  bash run_accent.sh --nj 20 --steps 4 data exp
  bash run_accent.sh --nj 20 --steps 6 data exp
```
  3. ASR initialization
  In order to get better results, the encoder of ASR model can be used to initialize the encoder of accent recognition model.
  As in the `run_accent.sh` script, you can set the value of `pretrained_model` variable to you asr model path.
  Then use the following command to run.
```
  bash run_accent.sh --nj 20 --steps 5 data exp
```
  4. In addition, in order to better reproduce and avoid you training asr system again, I uploaded two ASR models, including `pretrained_model/accent160.val5.avg.best` and `pretrained_model/accent160_and_librispeech960.val5.avg.best`. One is trained use only accent160 data, the other is both use accent160 and librispeech960 data.
  You can use these two models by change the `pretrained_model` variable values. 
## Transformer ASR system
  The purpose of training the asr model is to initialize the accent recogniton model. Because ASR training is no different from normal transformer training, there is no need to prepare additional model files. You can directly execute the `run_accent160_asr.sh` script step by step. Features can directly use the features of single accent system(steps 01-02).
```   
  bash run_accent160_asr.sh --nj 20 --steps 1-2 data exp
  bash run_accent160_asr.sh --nj 20 --steps 3 data exp
  bash run_accent160_asr.sh --nj 20 --steps 4 data exp
  bash run_accent160_asr.sh --nj 20 --steps 5 data exp
  bash run_accent160_asr.sh --nj 20 --steps 7 data exp
  bash run_accent160_asr.sh --nj 20 --steps 9 data exp
```
## notice
```
  All scripts have three inputs: data exp step
  data: Directory for storing data preparation
  exp: Output directory during training
  steps: Control execution parameters
```  
  For librispeech data, you can prepare librispeech data into kaldi format, and then mix it with accent data to train the asr system
  
