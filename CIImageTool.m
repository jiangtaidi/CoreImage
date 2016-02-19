//
//  CIImageTool.m
//  CoreImageDemo
//
//  Created by jiangtd on 15/12/25.
//  Copyright © 2015年 jiangtd. All rights reserved.
//

#import "CIImageTool.h"

//-(void)createContent
//{
//    //第一种，创建基于CPU的CIContent对象
//    CIContext *content = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
//    //第二种，创建基于GUP的 CIContent对象
//    CIContext *content = [CIContext contextWithOptions:nil];
//    //第三种，创建基于OpenGL优化的CIContent对象，需要导入OpenGL ES框架
//    EAGLContext *eagContent = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
//    CIContext *content = [CIContext contextWithEAGLContext:eagContent];
//    
//}

@implementation CIImageTool

//混合滤镜-CISourceAtopCompositing
+(UIImage*)sourceAtopCompositingWithTopImage:(UIImage*)topImage back:(UIImage*)backImage content:(CIContext*)content
{
    if (!topImage || !backImage) {
        return nil;
    }
    CIImage *topCIImage = [CIImage imageWithCGImage:topImage.CGImage];
    CIImage *backCIImage = [CIImage imageWithCGImage:backImage.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CISourceAtopCompositing"];
    [filter setValue:topCIImage forKey:kCIInputImageKey];
    [filter setValue:backCIImage forKey:@"inputBackgroundImage"];
    
    CIImage *outPutImage = [filter outputImage];
    
    UIImage *image = [self imageFromCIImage:outPutImage content:content];
    return image;
}

//拉直滤镜-CIStraightenFilter
+(UIImage*)staightenFilterWithImage:(UIImage*)img angle:(CGFloat)angle content:(CIContext*)content
{
    if (!img || angle < 0) {
        return nil;
    }
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIStraightenFilter"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:@(angle) forKey:@"inputAngle"];
    CIImage *outPutImage = [filter outputImage];
    return [self imageFromCIImage:outPutImage content:content];
}

//色彩控制滤镜-CIColorControls
+(UIImage*)colorControlsWithImage:(UIImage*)img  brightness:(CGFloat)brightness contrast:(CGFloat)inputContrast staturation:(CGFloat)inputStaturation content:(CIContext*)content
{
    if (!img) {
        return nil;
    }
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    if (brightness >= -1 && brightness <= 1) {
        [filter setValue:@(brightness) forKey:@"inputBrightness"];
    }
    if (inputContrast >= 0.25 && inputContrast <= 4) {
        [filter setValue:@(inputContrast) forKey:@"inputContrast"];
    }
    if (inputStaturation >= 0 && inputStaturation <= 2) {
        [filter setValue:@(inputStaturation) forKey:@"inputSaturation"];
    }
    return  [self imageFromCIImage:[filter outputImage] content:content];

}

//反转颜色滤镜-CIColorInvert
+(UIImage*)colorInvertWithImage:(UIImage*)img content:(CIContext*)content
{
    if (!img) {
        return nil;
    }
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setValue:[CIImage imageWithCGImage:img.CGImage] forKey:kCIInputImageKey];
    return [self imageFromCIImage:[filter outputImage] content:content];
}

//人脸检测
+(BOOL)hasFace:(UIImage*)img content:(CIContext*)content
{
    if (!img) {
        return NO;
    }
   
    return ((NSArray*)[self featuresWithImage:img content:content]).count?YES:NO;

}

+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image context:(CIContext*)context withSize:(CGFloat)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    if (!context) {
        context = [CIContext contextWithOptions:nil];
    }
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

//生成二维码-CIQRCodeGenerator
+(UIImage*)createRQCodeImageWithString:(NSString*)dataStr context:(CIContext*)context size:(CGFloat)size
{
    if (!dataStr) {
        return nil;
    }
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage *ciImage = [filter outputImage];
    return [self createNonInterpolatedUIImageFormCIImage:ciImage context:context withSize:size];
}

//检测二维码
+(NSString*)rqStringWithImage:(UIImage*)img content:(CIContext*)context
{
    NSString *resultStr = nil;
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    NSArray *features = [detector featuresInImage:ciImage];
    for (CIQRCodeFeature *feature in features) {
        if (feature.messageString && ![feature.messageString isEqualToString:@""]) {
            resultStr = feature.messageString;
            break;
        }
    }
    return resultStr;
}

//获得左眼/右眼/嘴部位置
+(NSArray*)facePartPositionWithImage:(UIImage*)img content:(CIContext*)content type:(FacePartType)type;
{
    if (!img) {
        return nil;
    }
    
    NSArray *features = [self featuresWithImage:img content:content];
    if (!features && features.count <=0) {
        return nil;
    }
    NSMutableArray *resultArr = [NSMutableArray array];
    NSArray *hasType = @[@"hasLeftEyePosition",@"hasRightEyePosition",@"hasMouthPosition"];
    NSArray *typeValue = @[@"leftEyePosition",@"rightEyePosition",@"mouthPosition"];
    for (CIFaceFeature *feature in features) {
    
        NSLog(@"mouth:%@",NSStringFromCGPoint(feature.mouthPosition));
        if ([((NSNumber*)[feature valueForKey:hasType[(NSInteger)type]]) boolValue]) {
            [resultArr addObject:[feature valueForKey:typeValue[(NSInteger)type]]];
        }
    }
    return resultArr;
}

//棕色滤镜-CISepiaTone
+(UIImage*)sepiaToneWithImage:(UIImage*)img intentsity:(CGFloat)intentsity content:(CIContext*)content
{
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
   
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    if (intentsity>=0 && intentsity<=1) {
        [filter setValue:@(intentsity) forKey:@"inputIntensity"];
    }
    CIImage *outPutImg = [filter outputImage];
    return [self imageFromCIImage:outPutImg content:content];
}

//模糊滤镜-CIGaussianBlur
+(UIImage*)gaussianBlurWithImage:(UIImage*)img radiur:(CGFloat)radiur content:(CIContext*)content
{
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    if (radiur>=0 && radiur<=100) {
        [filter setValue:@(radiur) forKey:@"inputRadius"];
    }
    CIImage *outPutImage = [filter outputImage];
    return [self imageFromCIImage:outPutImage content:content];
    
    
}

//鱼眼滤镜－CIBumpDistortion
+(UIImage*)bumpDistortionWithImage:(UIImage*)img scale:(CGFloat)scale radius:(CGFloat)radius center:(CGPoint)center content:(CIContext*)content
{
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIBumpDistortion"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    if (scale>=-1 && scale<=1) {
        [filter setValue:@(scale) forKey:@"inputScale"];
    }
    if (radius>=0 && radius<=600) {
        [filter setValue:@(radius) forKey:@"inputRadius"];
    }
    CIVector *vector = [CIVector vectorWithCGPoint:center];
    [filter setValue:vector forKey:@"inputCenter"];
    CIImage *outPutImg = [filter outputImage];
    return [self imageFromCIImage:outPutImg content:content];
}

//色彩滤镜-CIHueAdjust
+(UIImage*)hueAdjustWithImage:(UIImage*)img  angle:(CGFloat)angle content:(CIContext*)content
{
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    CIFilter *filter =[CIFilter filterWithName:@"CIHueAdjust"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    if (angle >= -M_PI && angle <= M_PI) {
        [filter setValue:@(angle) forKey:@"inputAngle"];
    }
    CIImage *outPutImage =[filter outputImage];
    return [self imageFromCIImage:outPutImage content:content];
    
}

//像素滤镜-CIPixellate
+(UIImage*)pixellateWithImage:(UIImage*)img center:(CGPoint)center scale:(CGFloat)scale content:(CIContext*)content
{
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIPixellate"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    if (scale>=1 && scale<=100) {
        [filter setValue:@(scale) forKey:@"inputScale"];
    }
    CIVector *vector = [CIVector vectorWithCGPoint:center];
    [filter setValue:vector forKey:@"inputCenter"];
    CIImage *outputImg = [filter outputImage];
    return [self imageFromCIImage:outputImg content:content];
}

+(NSArray*)featuresWithImage:(UIImage*)img content:(CIContext*)content
{
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:content options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    CIImage *ciImage = [CIImage imageWithCGImage:img.CGImage];
    NSArray *features = [detector featuresInImage:ciImage];
    return features;
}

+(UIImage*)imageFromCIImage:(CIImage*)ciImage content:(CIContext*)content
{
    UIImage *image = nil;
    if (content) {
        CGImageRef imageRef = [content createCGImage:ciImage fromRect:[ciImage extent]];
        image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
    else
    {
        image = [UIImage imageWithCIImage:ciImage];
    }
   
    return image;
}

@end








