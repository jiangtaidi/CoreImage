//
//  CIImageTool.h
//  CoreImageDemo
//
//  Created by jiangtd on 15/12/25.
//  Copyright © 2015年 jiangtd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>

#define CIImageNoneParam -99

typedef NS_ENUM(NSInteger,FacePartType) {
    FacePartTypeLeftEye = 0,
    FacePartTypeRightEye = 1,
    FacePartTypeMouth = 2,
};

@interface CIImageTool : NSObject

//混合滤镜 
+(UIImage*)sourceAtopCompositingWithTopImage:(UIImage*)topImage back:(UIImage*)backImage content:(CIContext*)content;
//拉直滤镜
+(UIImage*)staightenFilterWithImage:(UIImage*)img angle:(CGFloat)angle content:(CIContext*)content;
//色彩控制滤镜
+(UIImage*)colorControlsWithImage:(UIImage*)img  brightness:(CGFloat)brightness contrast:(CGFloat)inputContrast staturation:(CGFloat)inputStaturation content:(CIContext*)content;
//反转颜色滤镜
+(UIImage*)colorInvertWithImage:(UIImage*)img content:(CIContext*)content;
//人脸检测
+(BOOL)hasFace:(UIImage*)img content:(CIContext*)content;
//获得左眼/右眼/嘴部位置
+(NSArray*)facePartPositionWithImage:(UIImage*)img content:(CIContext*)content type:(FacePartType)type;
//棕色滤镜
+(UIImage*)sepiaToneWithImage:(UIImage*)img intentsity:(CGFloat)intentsity content:(CIContext*)content;
//二维码
+(NSString*)rqStringWithImage:(UIImage*)img content:(CIContext*)context;
//生成二维码
+(UIImage*)createRQCodeImageWithString:(NSString*)dataStr context:(CIContext*)context size:(CGFloat)size;
//模糊滤镜
+(UIImage*)gaussianBlurWithImage:(UIImage*)img radiur:(CGFloat)radiur content:(CIContext*)content;
//鱼眼滤镜
+(UIImage*)bumpDistortionWithImage:(UIImage*)img scale:(CGFloat)scale radius:(CGFloat)radius center:(CGPoint)center content:(CIContext*)content;
//色彩滤镜
+(UIImage*)hueAdjustWithImage:(UIImage*)img  angle:(CGFloat)angle content:(CIContext*)content;
//像素滤镜
+(UIImage*)pixellateWithImage:(UIImage*)img center:(CGPoint)center scale:(CGFloat)scale content:(CIContext*)content;

@end








