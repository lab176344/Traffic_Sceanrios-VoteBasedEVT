###################################################################################################
import os
import matplotlib.pyplot as plt
import numpy as np
import random 
import scipy.io as sio
import h5py

import keras
from keras import backend as K
from keras.layers.convolutional import MaxPooling3D, Conv3D
from keras.layers.core import Dense, Dropout, Activation, Flatten
from keras.layers.normalization import BatchNormalization
from keras.models import Sequential, load_model, Model
from keras.optimizers import SGD, RMSprop, Adam
from keras.preprocessing.image import ImageDataGenerator
from keras.utils import np_utils, generic_utils
from keras.callbacks import TensorBoard
import tensorflow as tf
from keras.backend.tensorflow_backend import set_session
import keras.backend.tensorflow_backend as tfback

print("tf.__version__ is", tf.__version__)
print("tf.keras.__version__ is:", tf.keras.__version__)

def _get_available_gpus():
    """Get a list of available gpu devices (formatted as strings).

    # Returns
        A list of available GPU devices.
    """
    #global _LOCAL_DEVICES
    if tfback._LOCAL_DEVICES is None:
        devices = tf.config.list_logical_devices()
        tfback._LOCAL_DEVICES = [x.name for x in devices]
    return [x for x in tfback._LOCAL_DEVICES if 'device:gpu' in x.lower()]

tfback._get_available_gpus = _get_available_gpus

K.set_image_data_format('channels_first')



def get_few_class(rand_labels,nClass,xTrain,yTrain,xTest,yTest):

    # Train
    train_s,train_l = map(np.array, zip(*[(x,0) for (x,y) in zip(xTrain, yTrain)
                                        if y==rand_labels[0]]))
    
    test_s,test_l = map(np.array, zip(*[(x,0) for (x,y) in zip(xTest, yTest)
                                        if y==rand_labels[0]]))
    for i in range(1,nClass):
        ltrain_s,ltrain_l = map(np.array, zip(*[(x,i) for (x,y) in zip(xTrain, yTrain)
                                            if y==rand_labels[i]]))
        
        ltest_s,ltest_l = map(np.array, zip(*[(x,i) for (x,y) in zip(xTest, yTest)
                                        if y==rand_labels[i]]))
        train_s = np.append(train_s, ltrain_s, axis=0)
        test_s = np.append(test_s, ltest_s, axis=0)
        train_l = np.append(train_l,ltrain_l)
        test_l = np.append(test_l,ltest_l)
        
    return train_s,train_l,test_s,test_l 

def main():
    for ranCheck in range(5):
        # Hyperparameters
        batch_size = 20
        nb_classes = 4
        nb_epoch = 20
        # Data parameters
        patch_size = 10  # full sequence size
        
        # Data settings from the mat files
        img_rows, img_cols, img_depth = 30, 200, 10  # image size
        
        
        # Load the mat file
        dataDir = 'HighDScenarioClass.mat'
        saveName='HighDScenarioClassification.h5'
        
        dict = sio.loadmat(dataDir)
        # numpy array to store the data
        x_complmat = dict["X_train"]
        y_complmat = dict["y_train"]
        x_testmat = dict["X_test"]
        y_testmat = dict["y_test"]
        x_openset = dict["x_openset"]
        y_openset = dict["y_openset"]
        
        
        # complete data to store the inout and labels
        train_data = [x_complmat, y_complmat]
        (X_train, y_train) = (train_data[0], train_data[1])
        print('X_Train shape:', X_train.shape)
        test_data = [x_testmat,y_testmat]
        (X_test, y_test) = (test_data[0], test_data[1])
        
        # reshape the train samples to 1d vector from 2d of matlb
        y_train = np.squeeze(y_train)
        y_test = np.squeeze(y_test)
        y_openset = np.squeeze(y_openset)
        
        random.seed(ranCheck)
        label_gen=random.sample(range(7),7)
        rand_label = label_gen[0:nb_classes]
        urand_label = label_gen[nb_classes:]
        train_s, train_l,test_s,test_l = get_few_class(rand_label, nb_classes, X_train, y_train, X_test, y_test)
        utrain_s, utrain_l,utest_s,utest_l = get_few_class(urand_label, 3, X_train, y_train, X_test, y_test)
        train_test = True
        if train_test:
            X_train   = train_s
            y_train   = train_l
            y_train_0 = train_l
            y_test    = train_l
            X_test    = test_s 
            y_test    = test_l
            y_test_o  = test_l
            label     = rand_label
            
        y_RejGt = np.zeros((y_openset.size))
        
        XOpenset,yOpenset = map(np.array, zip(*[(x,0) for (x,y) in zip(x_openset, y_openset)
                                            if y==rand_label[0]]))
        XOpenSetRej, yOpenSetRej = map(np.array, zip(*[(x,1) for (x,y) in zip(x_openset, y_openset)
                                            if y==rand_label[0]]))
        
        for classCheck in range(1,nb_classes):
            ltrain_s,ltrain_l = map(np.array, zip(*[(x,classCheck) for (x,y) in zip(x_openset, y_openset)
                                                if y==rand_label[classCheck]]))
            ltrain_sRej, ltrain_lRej = map(np.array, zip(*[(x,1) for (x,y) in zip(x_openset, y_openset)
                                            if y==rand_label[classCheck]]))
        
            XOpenset = np.append(XOpenset, ltrain_s, axis=0)
            yOpenset = np.append(yOpenset,ltrain_l)
            XOpenSetRej = np.append(XOpenSetRej, ltrain_sRej, axis=0)
            yOpenSetRej = np.append(yOpenSetRej,ltrain_lRej)
        
        for classCheck in range(3):
            ltrain_s,ltrain_l = map(np.array, zip(*[(x,4) for (x,y) in zip(x_openset, y_openset)
                                                if y==urand_label[classCheck]]))
            ltrain_sRej, ltrain_lRej = map(np.array, zip(*[(x,0) for (x,y) in zip(x_openset, y_openset)
                                            if y==urand_label[classCheck]]))
        
            XOpenset = np.append(XOpenset, ltrain_s, axis=0)
            yOpenset = np.append(yOpenset,ltrain_l)
            XOpenSetRej = np.append(XOpenSetRej, ltrain_sRej, axis=0)
            yOpenSetRej = np.append(yOpenSetRej,ltrain_lRej)
        
        num_samples = X_train.shape
        print(num_samples)
        num_test= X_test.shape
        print(num_test)
        num_open = x_openset.shape
        print(num_open)
        
        
        # prepare the whole dataset for NN as per the format required
        train_set = np.zeros((num_samples[0], 1, img_rows, img_cols, img_depth))
        test_set  = np.zeros((num_test[0], 1, img_rows, img_cols, img_depth))
        open_set  = np.zeros((num_open[0], 1, img_rows, img_cols, img_depth))
        
        for h in range(num_samples[0]):
            train_set[h][0][:][:][:] = X_train[h, :, :, :]
        for l in range(num_test[0]):
            test_set[l][0][:][:][:] = X_test[l, :, :, :]
        for m in range(num_open[0]):
            open_set[m][0][:][:][:] = XOpenset[m, :, :, :]
            
            
        print(train_set.shape, 'train samples')
        print(test_set.shape, 'train samples')
        print(open_set.shape, 'Open set samples')
        
        # Categorical values
        Y_train = np_utils.to_categorical(y_train, nb_classes)
        Y_test  = np_utils.to_categorical(y_test, nb_classes)
        
        # Define model
        model = Sequential()
        print('input shape', img_rows, 'rows', img_cols, 'cols', patch_size, 'patchsize')
        model.add(Conv3D(filters=8,
                        kernel_size=(4, 12, 3),
                        strides=(1, 1, 1),
                        input_shape=(1, img_rows, img_cols, patch_size),
                        activation='relu'
                        ))
        
        model.add(MaxPooling3D(pool_size=(3, 3, 1)))
        model.add(Dropout(0.25))
        model.add(Conv3D(
            8,
            kernel_size=(4, 8, 3),
            strides=(1, 1, 1),
            activation='relu'
            ))
        model.add(MaxPooling3D(pool_size=(2, 3, 1)))
        model.add(Dropout(0.25))
        
        model.add(Conv3D(
            6,
            kernel_size=(2, 2, 2),
            strides=(1, 1, 1),
            activation='relu'
            ))
        
        model.add(Flatten())
        model.add(Dense(500, activation='relu'))
        model.add(Dense(50, activation='relu'))
        model.add(Dense(nb_classes))
        model.add(Activation('softmax'))
        
        ada_opt=keras.optimizers.Adam(lr=0.001, beta_1=0.9, beta_2=0.999, epsilon=None, decay=0.0, amsgrad=False)
        
        model.compile(loss='categorical_crossentropy', optimizer=keras.optimizers.Adadelta(), metrics=['mse', 'accuracy'])
        print(model.summary())
        
        
        # Train the model
        hist = model.fit(
            train_set,
            Y_train,
            validation_data=(test_set, Y_test),
            batch_size=batch_size,
            epochs=nb_epoch,
            shuffle=True,
        )
        
        #Save the model
        model.save(saveName)
        # Evaluate the model
        score = model.evaluate(
            test_set,
            Y_test,
            batch_size=batch_size
        )
        
        # RF+EVT 
        
        # extract features
        feature_model = Model(inputs=model.input, outputs=model.get_layer(index = 7).output)
        features = feature_model.predict(train_set)
        print('Train feature', features.shape)
        print('Train target', y_train.shape)

    
        calib_train_features = feature_model.predict(test_set)   
        open_train_features = feature_model.predict(open_set)
    
        output_Train = {}
        output_Calib = {}
        output_Test  = {}
        
        output_Train['XTrain'] = features
        output_Train['yTrain'] = y_train
        output_Train['Scores'] = score

        save_train_features = 'Train\Train_Features'+str(ranCheck)+'.mat' 
        sio.savemat(save_train_features, output_Train)

        save_test_features = 'Train\Calib\Calib_Features'+str(ranCheck)+'.mat' 
        output_Calib['XCalib'] = calib_train_features
        output_Calib['yCalib'] = y_test
        sio.savemat(save_test_features, output_Calib)

        output_Test['XTest'] = open_train_features
        output_Test['yTest'] = yOpenset
        output_Test['YRej'] = yOpenSetRej
        save_open_features = 'Train\Test\Test_Features'+str(ranCheck)+'.mat' 
        sio.savemat(save_open_features, output_Test)
        
            # Openmax
    
        # extract features
        feature_model = Model(inputs=model.input, outputs=model.get_layer(index = 10).output)
        features = feature_model.predict(train_set)
        print('Train feature', features.shape)
        print('Train target', y_train.shape)
    
        import pickle
        # save latent space features 128-d vector
        save_train_features = 'OpenMaxTrainFeatures'+str(ranCheck)+'.pickle' 
        save_train_labels = 'OpenMaxTrainLabels'+str(ranCheck)+'.pickle'
        pickle.dump(features, open(save_train_features, 'wb'))
        pickle.dump(y_train, open(save_train_labels, 'wb'))
    
    
        softmax_model = Model(inputs=model.input, outputs=model.get_layer(index = 11).output)
    
        open_train_features = feature_model.predict(open_set)
        open_train_softmax = softmax_model.predict(open_set)
        # save latent space features 128-d vector
        output_open = {}
        output_open["OpenTrainFeatures"] = features
        output_open["OpenTrainLabels"] = y_train
        output_open["OpenTestFeatures"] = open_train_features
        output_open["OpenTestLabels"] = yOpenset
        output_open["SoftMaxScores"] = open_train_softmax
        save_open_features = 'Open_Test_Features'+str(ranCheck)+'.mat' 
        sio.savemat(save_open_features, output_open)
    
        print('Open feature', open_train_features.shape)
        print('Open target', y_openset.shape)
        
if __name__=="__main__":
    main()
        
    

        
        
        
