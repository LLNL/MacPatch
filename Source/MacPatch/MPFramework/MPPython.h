//
//  MPPython.h
//  PyRunner
//
//  Created by Charles Heizer on 11/14/17.
//  Copyright © 2017 Charles Heizer. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Python/Python.h"

@interface MPPython : NSObject

@property (nonatomic, weak) NSString *virtualEnvPath;

/**
 <#Description#>

 @param runPySimpleScript <#runPySimpleScript description#>
 @param aScript <#aScript description#>
 @param error <#error description#>
 @return <#return value description#>
 */
- (id)initWithVirtualEnv:(NSString *)vEnvPath;

/**
 Run a python script, no input and no return values
 
 @param aScript Python Script string
 @param error NSError or NULL
 @return return code
 */
- (int)runPySimpleScript:(NSString *)aScript error:(NSError **)error;

/**
 Run Python Script method in the main name space
 
 @param aScript Python Script string
 @param defName Name of python method
 @param error NSError or NULL
 @return return id type object of the method
 */
- (id)runPyScriptDef:(NSString *)aScript def:(NSString *)defName error:(NSError **)error;

/**
 Run Python Script and get the value of a global variable
 
 @param aScript Python Script string
 @param varName Variable Name
 @param error NSError or NULL
 @return return id type object of the method
 */
- (id)runPyScriptGetValueFromVariable:(NSString *)aScript variable:(NSString *)varName error:(NSError **)error;

// Python PyObject Helpers

/**
 Return id object from PyObject
 Will determin the Python Object Type and return
 a Objective C class type.
 
 @param pyObj Python C PyObjct
 @return returns an id on any NSObject type
 */
- (id)idFromPyObject:(PyObject *)pyObj;

/**
 Python PyObject List type to NSArray
 
 @param pList Python List Object
 @return NSArray
 */
- (NSArray *)arrayFromPyObject:(PyObject *)pList;

/**
 Python PyObject String type to NSString
 
 @param pStr Python string object
 @return NSString
 */
- (NSString *)stringFromPyObject:(PyObject *)pStr;

/**
 Python PyObject Dictionary type to NSDictionary
 
 @param pDict Python Dictionary type
 @return NSDictionary
 */
- (NSDictionary *)dictionaryFromPyObject:(PyObject *)pDict;

@end
