//
//  PhoneSettings.h
//  CommonProject
//
//  Created by lileilei on 15/9/24.
//

#import "IASKSettingsStore.h"
#import "IASKSettingsStore.h"

#import "LinphoneManager.h"

@interface PhoneSettings : IASKAbstractSettingsStore{
@private
    NSDictionary *dict;
    NSDictionary *changedDict;
}

- (void)synchronizeAccount;
- (void)transformLinphoneCoreToKeys;

@end
