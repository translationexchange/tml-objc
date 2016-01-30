/*
 *  Copyright (c) 2014 Michael Berkovich, http://tr8nhub.com All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

#import "TMLConfiguration.h"
#import "TMLTestBase.h"

@interface TMLConfigurationTest : TMLTestBase

@end

@implementation TMLConfigurationTest

- (void) testUpdateSettings {
    TMLConfiguration *config = [[TMLConfiguration alloc] init];
    
    XCTAssert([[config defaultLocale] isEqual:@"en"]);
    config.currentLocale = @"en-US";
    XCTAssert([[config currentLocale] isEqual:@"en-US"]);
    
    config.currentLocale = @"ru";
    XCTAssert([[config currentLocale] isEqual:@"ru"]);
}

- (void) testConfigurarionBlock {
    TMLConfiguration *config = [[TMLConfiguration alloc] init];
    config.applicationKey = @"foobar";
    config.accessToken = @"foobat";
    config.currentLocale = @"en-US";
    XCTAssert([[config currentLocale] isEqual:@"en-US"]);
    
    [TML sharedInstanceWithConfiguration:config];
    
    config.currentLocale = @"ru";
    
    XCTAssert([[config currentLocale] isEqual:@"ru"]);
}

- (void) testVariableMethods {
    TMLConfiguration *config = [[TMLConfiguration alloc] init];
    id method = [config variableMethodForContext:@"gender" andVariableName:@"@gender"];
    XCTAssert([method isEqual:@"@gender"]);
    
    [config setVariableMethod:@"@@name" forContext:@"sample" andVariableName:@"var"];
    method = [config variableMethodForContext:@"sample" andVariableName:@"var"];
    XCTAssert([method isEqual:@"@@name"]);

    [config setVariableMethod:^(NSObject *obj) { return @"Michael"; } forContext:@"sample1" andVariableName:@"var1"];
    method = [config variableMethodForContext:@"sample1" andVariableName:@"var1"];
    XCTAssert([method isKindOfClass:NSClassFromString(@"NSBlock")]);
    
}

@end
