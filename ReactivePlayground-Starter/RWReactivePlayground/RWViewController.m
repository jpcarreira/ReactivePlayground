//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (nonatomic) BOOL passwordIsValid;
@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self updateUIState];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
  [self.usernameTextField addTarget:self action:@selector(usernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
    
    
    // changing the text field background colors using 2 separate pipelines
    [self updateTextFieldBackgroundColorUsingRAC];
    

}


// basic examples using ReactiveCocoa, call this at the end of viewDidLoad
-(void)reactiveExamples
{
    // example 1: logs any char entered in the text field
        [self.usernameTextField.rac_textSignal subscribeNext:^(id x){
            NSLog(@"%@", x);
        }];
    
    
    // example 2: only logs text longer than 3 chars
        [[self.usernameTextField.rac_textSignal filter:^BOOL(id value){
            NSString *text = value;
            return text.length > 3;
        }] subscribeNext:^(id x){
            NSLog(@"%@", x);
        }];
    
    
    // example 3: same as example 2 but showing all pipelines
        RACSignal *userNameSourceSignal = self.usernameTextField.rac_textSignal;
    
        RACSignal *filteredUserName = [userNameSourceSignal filter:^BOOL(id value){
            NSString *text = value;
            return text.length > 3;
        }];
    
        [filteredUserName subscribeNext:^(id x){
           NSLog(@"%@", x);
        }];
    
    
    // same as example 2 but without the id to NSString cast
       [[self.usernameTextField.rac_textSignal filter:^BOOL(NSString *text){
           return text.length > 3;
        }] subscribeNext:^(id x){
            NSLog(@"%@", x);
        }];
    
    
    // example 4: using map function to transform a NSString in NSNumber
        [[[self.usernameTextField.rac_textSignal map:^id(NSString *text){
            return @(text.length);
        }] filter:^BOOL(NSNumber *length){
            return [length integerValue] > 3;
        }] subscribeNext:^(id x){
            NSLog(@"%@", x);
        }];
}


// this method creates two separate pipelines (one for the username textfield and other for the password
// textfield) so that they change from orange to clear color once the number of chars in each textfield
// is greater than 3
-(void)updateTextFieldBackgroundColorUsingRAC
{
    // step 1: create a couple of signals that indicate whether the username and password text fields are valid
    
    // RAC signal to check if username is valid
    RACSignal *validUserNameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text){
        return @([self isValidUsername:text]);
    }];
    
    // RAC signal to check if password is valid
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    
    // in the code above we apply a map to transform the rac_textSignal from each text field, producing an
    // output that is a boolean value boxed as a NSNumber
    
    
    // step 2: transforming the signals so that they provide a background color to the text fields
    // (we assign the output of validPasswordSignal to the background color property of the text field
    // (password text field will remain red while number of chars is less than 3)
    
    //    [[validPasswordSignal map:^id(NSNumber *passwordValid) {
    //        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor redColor];
    //    }]
    //    subscribeNext:^(UIColor *color){
    //        self.passwordTextField.backgroundColor = color;
    //    }];
    
    
    // step 2 (alternative): using RAC macro to assign the output of a signal to the property of an object
    RAC(self.passwordTextField, backgroundColor) =
    [validPasswordSignal map:^id(NSNumber *passwordValid){
        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor orangeColor];
    }];
    
    RAC(self.usernameTextField, backgroundColor) =
    [validUserNameSignal map:^id(NSNumber *usernameValid){
        return [usernameValid boolValue] ? [UIColor clearColor] : [UIColor orangeColor];
    }];
    
//
//      this pipeline starts with a signal and ends up changing a property of the textfield
//
//      rac_textSignal --(NSString)--> map --(BOOL)--> map --(UIColor)--> backgroundColor
//    

}


- (BOOL)isValidUsername:(NSString *)username
{
  return username.length > 3;
}


- (BOOL)isValidPassword:(NSString *)password
{
  return password.length > 3;
}


- (IBAction)signInButtonTouched:(id)sender
{
  // disable all UI controls
  self.signInButton.enabled = NO;
  self.signInFailureText.hidden = YES;
  
  // sign in
  [self.signInService signInWithUsername:self.usernameTextField.text
                            password:self.passwordTextField.text
                            complete:^(BOOL success) {
                              self.signInButton.enabled = YES;
                              self.signInFailureText.hidden = success;
                              if (success) {
                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
                              }
                            }];
}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid
- (void)updateUIState
{
//  self.usernameTextField.backgroundColor = self.usernameIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.passwordTextField.backgroundColor = self.passwordIsValid ? [UIColor clearColor] : [UIColor yellowColor];
  self.signInButton.enabled = self.usernameIsValid && self.passwordIsValid;
}


- (void)usernameTextFieldChanged
{
  self.usernameIsValid = [self isValidUsername:self.usernameTextField.text];
  [self updateUIState];
}


- (void)passwordTextFieldChanged
{
  self.passwordIsValid = [self isValidPassword:self.passwordTextField.text];
  [self updateUIState];
}

@end
