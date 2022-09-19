//
//  RNAres.h
//  rn70
//
//  Created by lylaut on 2022/9/9.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>

// 处理原生成功时返回给RN的数据封装
///
/// - Parameter data: 要处理的数据
/// - Returns: RN结构的数据
NSArray *convertSuccessResponseData(id data);

NSDictionary *convertPromiseSuccessResponseData(id data);

@interface RNAres : NSObject <RCTBridgeModule>

@end
