/*
 Copyright (c) 2011-2014, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SFOAuthCoordinator.h"
#import "SFOAuthCredentials.h"
#import "SFOAuthKeychainCredentials.h"
#import "SFOAuthCredentials+Internal.h"
#import "SalesforceOAuthUnitTestsCoordinatorDelegate.h"
#import "SalesforceOAuthUnitTests.h"
#import "SFSDKCryptoUtils.h"

static NSString * const kIdentifier = @"com.salesforce.ios.oauth.test";
static NSString * const kClientId   = @"SfdcMobileChatteriOS";

@interface SalesforceOAuthUnitTests ()

- (void)verifySuccessfulTokenUpdate:(NSString *)accessToken refreshToken:(NSString *)refreshToken;
- (void)verifyUnsuccessfulTokenUpdate;

@end

@implementation SalesforceOAuthUnitTests

- (void)setUp {
    [super setUp];
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    [super tearDown];
}

/** Test the SFOAuthCredentials data model object
 */
- (void)testCredentials {
    
    NSString * const kAccessToken   = @"howAboutaNice";
    NSString * const kRefreshToken  = @"hawaiianPunch";
    NSString * const kUserId12      = @"00530000004c";          // 12 characters   00530000004cwSi
    NSString * const kUserId15      = @"00530000004cwSi";       // 15 characters
    NSString * const kUserId18      = @"00530000004cwSi123";    // 18 characters

    NSString * identifier       = kIdentifier;
    NSString * clientId         = kClientId;
    NSString * accessToken      = kAccessToken;
    NSString * refreshToken     = kRefreshToken;
    NSString * userId           = kUserId18;
    
    SFOAuthCredentials *credentials = [[SFOAuthCredentials alloc] initWithIdentifier:identifier clientId:clientId encrypted:YES];
    identifier = nil;
    clientId = nil;
    
    // the access and refresh tokens should only be set explicitly for test purposes
    credentials.accessToken  = accessToken;     accessToken = nil;
    credentials.refreshToken = refreshToken;    refreshToken = nil;
    credentials.userId       = userId;          userId = nil;
    
    XCTAssertEqualObjects(credentials.identifier, kIdentifier, @"identifier must match initWithIdentifier arg");
    XCTAssertEqualObjects(credentials.clientId, kClientId, @"client ID must match initWithIdentifier arg");
    XCTAssertEqualObjects(credentials.accessToken, kAccessToken, @"access token mismatch");
    XCTAssertEqualObjects(credentials.refreshToken, kRefreshToken, @"refresh token mismatch");
    XCTAssertEqualObjects(credentials.userId, kUserId15, @"user ID (18) mismatch/truncation issue");
    
    credentials.userId = kUserId12;
    XCTAssertEqualObjects(credentials.userId, kUserId12, @"user ID (12) mismatch/truncation issue");
    
    [credentials revokeAccessToken];
    XCTAssertNil(credentials.accessToken, @"access token should be nil");
    
    [credentials revokeRefreshToken];
    XCTAssertNil(credentials.refreshToken, @"refresh token should be nil");
    // userId, instanceUrl, and issuedAt should all be nil after the refresh token is revoked
    XCTAssertNil(credentials.userId, @"userId should be nil");
    XCTAssertNil(credentials.issuedAt, @"instanceUrl should be nil");
    XCTAssertNil(credentials.issuedAt, @"issuedAt should be nil");
    
    credentials.accessToken = kAccessToken;
    credentials.refreshToken = kRefreshToken;
    XCTAssertEqualObjects(credentials.accessToken, kAccessToken, @"access token mismatch");
    XCTAssertEqualObjects(credentials.refreshToken, kRefreshToken, @"refresh token mismatch");
    
    [credentials revoke];
    XCTAssertNil(credentials.accessToken, @"access token should be nil");
    XCTAssertNil(credentials.accessToken, @"refresh token should be nil");
    
    credentials = nil;
}

/** Test the case of instantiating the credentials using alloc/init, in which case the identifier and clientId will both be nil.
 The credentials class requires the identifier to be set for nearly all operations, therefore under these circumstances most 
 public methods will raise an exception.
 */
- (void)testCredentialsDefaultInstantiation {
    
    NSString * identifier       = nil;
    NSString * clientId         = nil;
    NSString * accessToken      = nil;
    NSString * refreshToken     = nil;
    NSString * userId           = nil;
    NSString * activationCode   = nil;
    
    SFOAuthCredentials *credentials = [[SFOAuthCredentials alloc] init];
    
    XCTAssertNotNil(credentials, @"credentials object should not be nil");
    XCTAssertThrows(accessToken = credentials.accessToken, @"should raise exception if no identifier is set");
    XCTAssertThrows(credentials.accessToken = nil, @"should raise exception if no identifier is set");
    XCTAssertNoThrow(credentials.clientId = nil, @"should not raise exception if no identifier is set and should allow a nil argument");
    XCTAssertNoThrow(clientId = credentials.clientId, @"should not raise exception if no identifier is set");
    XCTAssertNoThrow(identifier = credentials.identifier, @"should not raise exception if no identifier is set");
    XCTAssertNoThrow(credentials.identifier = nil, @"should not raise exception if set to nil");
    XCTAssertNoThrow(credentials.identityUrl = nil, @"should not raise exception if set to nil");
    XCTAssertThrows(refreshToken = credentials.refreshToken, @"should raise exception if no identifier is set");
    XCTAssertThrows(credentials.refreshToken = nil, @"should raise exception if no identifier is set");
    XCTAssertThrows(activationCode = credentials.activationCode, @"should raise exception if no identifier is set");
    XCTAssertThrows(credentials.activationCode = nil, @"should raise exception if no identifier is set");
    XCTAssertNoThrow(userId = credentials.userId, @"should not raise exception if no identifier is set");
    XCTAssertNoThrow(credentials.userId = nil, @"should not raise exception if no identifier is set and should allow a nil argument");
    XCTAssertThrows([credentials revokeAccessToken], @"should raise exception if no identifier is set");
    XCTAssertThrows([credentials revokeRefreshToken], @"should raise exception if no identifier is set");
    XCTAssertThrows([credentials revokeActivationCode], @"should raise exception if no identifier is set");
    
    credentials = nil;
}

/** Test the <NSCoding> implementation of <SFOAuthCredentials>
 */
- (void)testCredentialsCoding {
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    SFOAuthCredentials *credsIn = [[SFOAuthCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    credsIn.domain          = @"login.salesforce.com";
    credsIn.redirectUri     = @"sfdc:///axm/detect/oauth/done";
    credsIn.organizationId  = @"org";
    credsIn.identityUrl     = [NSURL URLWithString:@"https://login.salesforce.com/ID/orgID/eighteenCharUsrXYZ"];
    credsIn.instanceUrl     = [NSURL URLWithString:@"http://www.salesforce.com"];
    credsIn.issuedAt        = [NSDate date];
    
    NSString *expectedUserId = @"eighteenCharUsr"; // derived from identityUrl, 18 character ID's are truncated to 15 chars
    
    [archiver encodeObject:credsIn forKey:@"creds"];
    [archiver finishEncoding];
    archiver = nil;
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    SFOAuthCredentials * credsOut = [unarchiver decodeObjectForKey:@"creds"];
    unarchiver = nil;
    
    XCTAssertNotNil(credsOut, @"couldn't unarchive credentials");
    
    XCTAssertEqualObjects(credsIn.identifier,        credsOut.identifier,        @"identifier mismatch");
    XCTAssertEqualObjects(credsIn.clientId,          credsOut.clientId,          @"clientId mismatch");
    XCTAssertEqualObjects(credsIn.domain,            credsOut.domain,            @"domain mismatch");
    XCTAssertEqualObjects(credsIn.redirectUri,       credsOut.redirectUri,       @"redirectUri mismatch");
    XCTAssertEqualObjects(credsIn.organizationId,    credsOut.organizationId,    @"organizationId mismatch");
    XCTAssertEqualObjects(credsIn.identityUrl,       credsOut.identityUrl,       @"identityUrl mistmatch");
    XCTAssertEqualObjects(expectedUserId,            credsOut.userId,            @"userId mismatch");
    XCTAssertEqualObjects(credsIn.instanceUrl,       credsOut.instanceUrl,       @"instanceUrl mismatch");
    XCTAssertEqualObjects(credsIn.issuedAt,          credsOut.issuedAt,          @"issuedAt mismatch");
    
    credsIn = nil;
}

/** Test the SFOAuthCoordinator
 */
- (void)testCoordinator {
    
    SFOAuthCredentials *creds = [[SFOAuthCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    XCTAssertNotNil(creds, @"credentials should not be nil");
    creds.domain = @"localhost";
    creds.redirectUri = @"sfdc://expected/to/fail";
    creds.refreshToken = @"refresh-token";
    
    SFOAuthCoordinator *coordinator = [[SFOAuthCoordinator alloc] initWithCredentials:creds];
    XCTAssertNotNil(coordinator, @"coordinator should not be nil");
    SalesforceOAuthUnitTestsCoordinatorDelegate *delegate = [[SalesforceOAuthUnitTestsCoordinatorDelegate alloc] init];
    XCTAssertNotNil(delegate, @"delegate should not be nil");
    coordinator.delegate = delegate;
    XCTAssertNoThrow([coordinator authenticate], @"authenticate should not raise an exception");
    XCTAssertTrue([coordinator isAuthenticating], @"authenticating should return true");
    [coordinator stopAuthentication];
    XCTAssertFalse([coordinator isAuthenticating], @"authenticating should return false");
    
    coordinator = nil;
    delegate = nil;
}

/**
 Test the case of instantiating the SFOAuthCoordinator using alloc/init, in which case the credentials property will be nil
 and therefore calling the authenticate method will raise an exception. Calling authenticateWithCredentials with a nil
 argument should also raise an exception.
 */
- (void)testCoordinatorDefaultInstantiation {
    
    SFOAuthCoordinator *coordinator = [[SFOAuthCoordinator alloc] init];
    XCTAssertNotNil(coordinator, @"coordinator should not be nil");

    XCTAssertThrows([coordinator authenticate], @"authenticate with nil credentials should raise an exception");
    XCTAssertThrows([coordinator authenticateWithCredentials:nil], @"authenticate with nil credentials should raise an exception");
    
    coordinator = nil;
}

/** Test multiple identifiers.
 At this point, the test just ensures that the identifier is different then the client id.
 */
- (void)testMultipleUsers {
    
    NSString * const kUserA_Identifier   = @"userA";
    NSString * const kUserB_Identifier   = @"userB";    

    SFOAuthCredentials *ca = [[SFOAuthCredentials alloc] initWithIdentifier:kUserA_Identifier clientId:kClientId encrypted:YES];
    SFOAuthCredentials *cb = [[SFOAuthCredentials alloc] initWithIdentifier:kUserB_Identifier clientId:kClientId encrypted:YES];

    XCTAssertFalse([ca.identifier isEqual:ca.clientId], @"identifier and client id for user A must be different");
    XCTAssertFalse([cb.identifier isEqual:cb.clientId], @"identifier and client id for user B must be different");
    
    XCTAssertEqualObjects(ca.identifier, kUserA_Identifier, @"identifier for user A must match");
    XCTAssertEqualObjects(ca.clientId, kClientId, @"client id for user A must match");
    
    XCTAssertEqualObjects(cb.identifier, kUserB_Identifier, @"identifier for user B must match");
    XCTAssertEqualObjects(cb.clientId, kClientId, @"client id for user B must match");
    
    ca.clientId = @"testClientID";
    XCTAssertEqualObjects(ca.identifier, kUserA_Identifier, @"identifier must still match after changing clientId");
}

/**
 Test the various token encryption-and-decryption facilities.
 */
- (void)testTokenEncryptionDecryption
{
    NSString *accessToken = @"gimmeAccess!!!";
    NSString *refreshToken = @"IWannaRefresh!";
    SFOAuthKeychainCredentials *credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    
    NSDictionary *keyDict = @{
                              @"mac":
                                  @[ [credentials keyMacForService:kSFOAuthServiceAccess], [credentials keyMacForService:kSFOAuthServiceRefresh] ],
                              @"vendorId":
                                  @[ [credentials keyVendorIdForService:kSFOAuthServiceAccess], [credentials keyVendorIdForService:kSFOAuthServiceRefresh] ],
                              @"baseAppId":
                                  @[ [credentials keyBaseAppIdForService:kSFOAuthServiceAccess], [credentials keyBaseAppIdForService:kSFOAuthServiceRefresh] ],
                              @"keyStore":
                                  @[ [credentials keyStoreKeyForService:kSFOAuthServiceAccess], [credentials keyStoreKeyForService:kSFOAuthServiceRefresh] ]
                              };
    
    for (NSString *encTypeKey in [keyDict allKeys]) {
        NSArray *encTypeArray = keyDict[encTypeKey];
        
        // Same keys for supported encryption and decryption
        NSString *retrievedAccessToken;
        NSString *retrievedRefreshToken;
        if ([encTypeKey isEqualToString:@"keyStore"]) {
            [credentials setAccessToken:accessToken withSFEncryptionKey:encTypeArray[0]];
            [credentials setRefreshToken:refreshToken withSFEncryptionKey:encTypeArray[1]];
            retrievedAccessToken = [credentials accessTokenWithSFEncryptionKey:encTypeArray[0]];
            retrievedRefreshToken = [credentials refreshTokenWithSFEncryptionKey:encTypeArray[1]];
        } else {
            [credentials setAccessToken:accessToken withKey:encTypeArray[0]];
            [credentials setRefreshToken:refreshToken withKey:encTypeArray[1]];
            retrievedAccessToken = [credentials accessTokenWithKey:encTypeArray[0]];
            retrievedRefreshToken = [credentials refreshTokenWithKey:encTypeArray[1]];
        }
        XCTAssertEqualObjects(accessToken, retrievedAccessToken, @"Access tokens do not match between storage and retrieval for '%@'.", encTypeKey);
        XCTAssertEqualObjects(refreshToken, retrievedRefreshToken, @"Refresh tokens do not match between storage and retrieval for '%@'.", encTypeKey);
        
        // Different keys between encryption and decryption (i.e. failed decryption)
        NSData *badDecryptKey = [@"grarBogusKey!" dataUsingEncoding:NSUTF8StringEncoding];
        if ([encTypeKey isEqualToString:@"keyStore"]) {
            [credentials setAccessToken:accessToken withSFEncryptionKey:encTypeArray[0]];
            [credentials setRefreshToken:refreshToken withSFEncryptionKey:encTypeArray[1]];
            NSData *badIv = [SFSDKCryptoUtils randomByteDataWithLength:32];
            SFEncryptionKey *badEncryptionKey = [[SFEncryptionKey alloc] initWithData:badDecryptKey initializationVector:badIv];
            retrievedAccessToken = [credentials accessTokenWithSFEncryptionKey:badEncryptionKey];
            retrievedRefreshToken = [credentials refreshTokenWithSFEncryptionKey:badEncryptionKey];
        } else {
            [credentials setAccessToken:accessToken withKey:encTypeArray[0]];
            [credentials setRefreshToken:refreshToken withKey:encTypeArray[1]];
            retrievedAccessToken = [credentials accessTokenWithKey:badDecryptKey];
            retrievedRefreshToken = [credentials refreshTokenWithKey:badDecryptKey];
        }
        XCTAssertNil(retrievedAccessToken, @"For encType '%@', access token should be nil if it couldn't be decrypted.", encTypeKey);
        XCTAssertNil(retrievedRefreshToken, @"For encType '%@', refresh token should be nil if it couldn't be decrypted.", encTypeKey);
    }
    
    [credentials revoke];
}

- (void)testDefaultTokenEncryption
{
    NSString *accessToken = @"AllAccessPass$";
    NSString *refreshToken = @"RefreshFRESHexciting!";
    
    SFOAuthKeychainCredentials *credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    credentials.accessToken = accessToken;
    credentials.refreshToken = refreshToken;
    
    NSString *accessTokenVerify = [credentials accessTokenWithSFEncryptionKey:[credentials keyStoreKeyForService:kSFOAuthServiceAccess]];
    XCTAssertEqualObjects(accessToken, accessTokenVerify, @"Access token should decrypt to the same value.");
    NSString *refreshTokenVerify = [credentials refreshTokenWithSFEncryptionKey:[credentials keyStoreKeyForService:kSFOAuthServiceRefresh]];
    XCTAssertEqualObjects(refreshToken, refreshTokenVerify, @"Refresh token should decrypt to the same value.");
    SFOAuthCredsEncryptionType encType = [[NSUserDefaults standardUserDefaults] integerForKey:kSFOAuthEncryptionTypeKey];
    XCTAssertEqual(encType, kSFOAuthCredsEncryptionTypeKeyStore, @"Encryption type should be key store.");
    
    [credentials revoke];
}

/**
 Test the different token encryption update scenarios.
 */
- (void)testUpdateTokenEncryption
{
    NSString *accessToken = @"AccessGranted!";
    NSString *refreshToken = @"HowRefreshing";
    
    // Set MAC-key tokens, resetting update state to pre-update.
    SFOAuthKeychainCredentials *credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    [credentials setAccessToken:accessToken withKey:[credentials keyMacForService:kSFOAuthServiceAccess]];
    [credentials setRefreshToken:refreshToken withKey:[credentials keyMacForService:kSFOAuthServiceRefresh]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSFOAuthEncryptionTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // New credentials instantiation should convert the existing credentials to latest encryption scheme.
    [self verifySuccessfulTokenUpdate:accessToken refreshToken:refreshToken];
    
    // Set vendorId-key tokens, resetting update state to pre-update.
    credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    [credentials setAccessToken:accessToken withKey:[credentials keyVendorIdForService:kSFOAuthServiceAccess]];
    [credentials setRefreshToken:refreshToken withKey:[credentials keyVendorIdForService:kSFOAuthServiceRefresh]];
    [[NSUserDefaults standardUserDefaults] setInteger:kSFOAuthCredsEncryptionTypeIdForVendor forKey:kSFOAuthEncryptionTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // New credentials instantiation should convert the existing credentials to latest encryption scheme.
    [self verifySuccessfulTokenUpdate:accessToken refreshToken:refreshToken];
    
    // Set base app id tokens, resetting update state to pre-update.
    credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    [credentials setAccessToken:accessToken withKey:[credentials keyBaseAppIdForService:kSFOAuthServiceAccess]];
    [credentials setRefreshToken:refreshToken withKey:[credentials keyBaseAppIdForService:kSFOAuthServiceRefresh]];
    [[NSUserDefaults standardUserDefaults] setInteger:kSFOAuthCredsEncryptionTypeBaseAppId forKey:kSFOAuthEncryptionTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // New credentials instantiation should convert the existing credentials to latest encryption scheme.
    [self verifySuccessfulTokenUpdate:accessToken refreshToken:refreshToken];
    
    // Test update with bad MAC-key tokens (post-iOS7 scenario).
    NSString *badMacAddress = @"2F:00:00:00:00:00";
    credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    [credentials setAccessToken:accessToken withKey:[credentials keyWithSeed:badMacAddress service:kSFOAuthServiceAccess]];
    [credentials setRefreshToken:refreshToken withKey:[credentials keyWithSeed:badMacAddress service:kSFOAuthServiceRefresh]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSFOAuthEncryptionTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // New credentials instantiation should nil out the tokens, since they can't be converted in iOS7 and later.
    [self verifyUnsuccessfulTokenUpdate];
    
    // Test update with bad vendorId-key tokens (identifierForVendor inexplicably changes).
    NSString *badVendorId = @"2F:00:00:00:00:00";  // Not even a vendorId format.  Guaranteed to be bad.
    credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    [credentials setAccessToken:accessToken withKey:[credentials keyWithSeed:badVendorId service:kSFOAuthServiceAccess]];
    [credentials setRefreshToken:refreshToken withKey:[credentials keyWithSeed:badVendorId service:kSFOAuthServiceRefresh]];
    [[NSUserDefaults standardUserDefaults] setInteger:kSFOAuthCredsEncryptionTypeIdForVendor forKey:kSFOAuthEncryptionTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // New credentials instantiation should nil out the tokens, since they can't be converted in iOS7 and later.
    [self verifyUnsuccessfulTokenUpdate];
    
    [credentials revoke];
}

#pragma mark - Private methods

- (void)verifySuccessfulTokenUpdate:(NSString *)accessToken refreshToken:(NSString *)refreshToken
{
    SFOAuthKeychainCredentials *credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    NSString *accessTokenVerify = [credentials accessTokenWithSFEncryptionKey:[credentials keyStoreKeyForService:kSFOAuthServiceAccess]];
    XCTAssertEqualObjects(accessToken, accessTokenVerify, @"Access token should have been updated to key store encryption.");
    NSString *refreshTokenVerify = [credentials refreshTokenWithSFEncryptionKey:[credentials keyStoreKeyForService:kSFOAuthServiceRefresh]];
    XCTAssertEqualObjects(refreshToken, refreshTokenVerify, @"Refresh token should have been updated to key store encryption.");
    SFOAuthCredsEncryptionType encType = [[NSUserDefaults standardUserDefaults] integerForKey:kSFOAuthEncryptionTypeKey];
    XCTAssertEqual(encType, kSFOAuthCredsEncryptionTypeKeyStore, @"Encryption type should have been updated to key store.");
}

- (void)verifyUnsuccessfulTokenUpdate
{
    SFOAuthKeychainCredentials *credentials = [[SFOAuthKeychainCredentials alloc] initWithIdentifier:kIdentifier clientId:kClientId encrypted:YES];
    NSString *accessTokenVerify = credentials.accessToken;
    XCTAssertNil(accessTokenVerify, @"Access token should be nil, since it cannot be converted with bad inputs.");
    NSString *refreshTokenVerify = credentials.refreshToken;
    XCTAssertNil(refreshTokenVerify, @"Refresh token should be nil, since it cannot be converted with bad inputs.");
    SFOAuthCredsEncryptionType encType = [[NSUserDefaults standardUserDefaults] integerForKey:kSFOAuthEncryptionTypeKey];
    XCTAssertEqual(encType, kSFOAuthCredsEncryptionTypeKeyStore, @"Encryption type still should have been updated to key store.");
}

@end
