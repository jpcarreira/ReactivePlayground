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

@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.signInService = [RWDummySignInService new];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
    
    
    // changing the text field background colors using 2 separate pipelines
    [self updateTextFieldBackgroundColorUsingRAC];
    
    // enabling the sign in button using RAC
    [self enableSignInButtonUsingRAC];
    
    // signing in using RAC
    [self signInUsingRAC];
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


// this method enables the sign-in button combining RAC signals
-(void)enableSignInButtonUsingRAC
{
    // RAC signal to check if username is valid
    RACSignal *validUserNameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text){
        return @([self isValidUsername:text]);
    }];
    
    // RAC signal to check if password is valid
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    
    // using combineLastest:reduce: to combine the latest values emitted by validUserNameSignal and
    // validPasswordSignal into a new signal
    // (each time either of these signals emit a new value the reduce block will execute and the
    // value it returns is sent as the next value of the combined signal)
    RACSignal *signUpActiveSignal =
        [RACSignal combineLatest:@[validUserNameSignal, validPasswordSignal]
            reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
                return @([usernameValid boolValue] && [passwordValid boolValue]);
                }];
    
    [signUpActiveSignal subscribeNext:^(NSNumber *signupActive){
        self.signInButton.enabled = [signupActive boolValue];
    }];
}


// this method allows a sign-in using RAC signal for control events
-(void)signInUsingRAC
{
    // we use the map function to transform the button touch signal into the sign-in signal
    // and the subscriber simply logs the result
    //
    // we must use flattenMap: instead of map:
    //
    // if we use map: what happens is that the rac_signalForControlEvents emits a next event
    // (with the source UIButton as its event data) when we tap the button; the map step creates and returns
    // the sign-in signal with means the pipeline steps receives a RACSignal; this corresponds to "signal of
    // signals", that is, an outer signal that contains a inner signal; we could subscribe to the inner signal
    // within the outter signal but this could result is a mess so we use flattenMap:, which maps the button
    // touch event to a sign-in signal as before but also flattens it by sending the events from the inner
    // signal to the outer signal
    //
    // we add side-effects using doNext:
    // (the doNext: block does not return a value because it's a side-effect, i.e., it leaves the event
    // itlself unchanged)
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
       doNext:^(id x){
          self.signInButton.enabled = NO;
          self.signInFailureText.hidden = YES;
      }]
     flattenMap:^id(id x){
         return [self signInSignal];
     }]
     subscribeNext:^(NSNumber *signedIn){
         self.signInButton.enabled = YES;
         BOOL success = [signedIn boolValue];
         self.signInFailureText.hidden = success;
         if(success)
         {
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
    }];
}


- (BOOL)isValidUsername:(NSString *)username
{
  return username.length > 3;
}


- (BOOL)isValidPassword:(NSString *)password
{
  return password.length > 3;
}


// returns a RAC signal corresponding to the sign-in
-(RACSignal *)signInSignal
{
    // we create a signal and the block that describes this signal is a single argument and is passed
    // to this method; when the signal has a subscriber the code within the block executes
    //
    // the block is passed a single subscriber that adopts the RACSubscriber protocol which has methods
    // we invoke in order to emit events
    //
    // we can send any number of next events terminated with either an error or complete event but, in this
    // case we send a single next event to indicate whether the sign-in was successfull or not, followed
    // by a complete event
    //
    // the return type is a RACDisposable that allows to perform any cleanup work that might be required
    // when a subscription is cancelled or trashed; has this signal has no clean-up requirements we simply
    // return nil
    //
    // this sums up an assynchronous API call in a signal
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
       [self.signInService signInWithUsername:self.usernameTextField.text
                                     password:self.passwordTextField.text
                                     complete:^(BOOL success){
                                         [subscriber sendNext:@(success)];
                                         [subscriber sendCompleted];
                                     }];
        return nil;
    }];
}

@end
