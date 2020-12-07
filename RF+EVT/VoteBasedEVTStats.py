
from sklearn.metrics import precision_recall_fscore_support
import scipy.io as sio
import numpy as np
import decimal

def drange(x, y, jump):
  while x < y:
    yield float(x)
    x += decimal.Decimal(jump)
score=[]
ThresholdScore=[]
ThresMacro=[]
threshhold = list(drange(0, 1, '0.05'))
for j in range(1,22):
    FolderName='ScenarioSplit4_3_RF'+str(j)+'\\'
    score=[]
    macroScore=[]
    print('threshold', str(threshhold[j-1]))
    for i in range(2,6):
        loadName=FolderName+'fcheck'+str(i)+'.mat'
        dict=sio.loadmat(loadName)
        testy_PredMac=dict['outputknown']
        testy_GTMac=dict['outputTrue']
        testy_PredMac=np.transpose(testy_PredMac)
        testy_PredMac=np.reshape(testy_PredMac,[testy_PredMac.shape[0]])
        testy_GTMac=np.transpose(testy_GTMac)
        testy_GTMac=np.reshape(testy_GTMac,[testy_GTMac.shape[0]])
        precision,recall,fscore,_=precision_recall_fscore_support(testy_GTMac,testy_PredMac,average='macro')
        # print(np.mean(fscore))
        macroScore.append(np.mean(fscore))
        print('Macro F Score', fscore)  
    print('---------------------------')
    print('Five F Score', np.mean(fscore))  
    print('---------------------------')


