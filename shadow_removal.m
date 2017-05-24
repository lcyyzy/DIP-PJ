% SHADOW DETECTION
    % MASK: creating a shadow segmentation if no mask is available
    gray = rgb2gray(image);
    light_mask = double(bwareaopen(im2bw(gray, graythresh(gray)),200));
    h = fspecial('gaussian',200,0.5);
    light_mask = imfilter(light_mask,h);
    shadow_mask = 1 - light_mask;
    

    % SHADOW / LIGHT CORE DETECTION
    % structuring element
    struct_elem = [0 1 1 1 0; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 0 1 1 1 0];
    
    % shadow/light  core (morphology erode: pixels not on the blurred edge of the shadow area)
    shadow_core = imerode(shadow_mask, struct_elem);
    light_core = imerode(light_mask, struct_elem);
    % smoothing the mask
    smoothmask = conv2(shadow_mask, struct_elem/sum(sum(struct_elem)), 'same');
    
    % AVERAGE PIXEL INTENSITIES
    % shadow area
    shadow_avg_red = sum(sum(image(:,:,1).*shadow_core)) / sum(sum(shadow_core));
    shadow_avg_green = sum(sum(image(:,:,2).*shadow_core)) / sum(sum(shadow_core));
    shadow_avg_blue = sum(sum(image(:,:,3).*shadow_core)) / sum(sum(shadow_core));
    % light area
    light_avg_red = sum(sum(image(:,:,1).*light_core)) / sum(sum(light_core));
    light_avg_green = sum(sum(image(:,:,2).*light_core)) / sum(sum(light_core));
    light_avg_blue = sum(sum(image(:,:,3).*light_core)) / sum(sum(light_core));

%     % K-MEANS CLUSTERING
%     im_hsv = rgb2hsv(image);
%     data = zeros(s_im(1)*s_im(2), 5);
%     for r=1:s_im(1)
%         for c=1:s_im(2)
%             data(r,:) = [im_hsv(r,c,1), im_hsv(r,c,2), im_hsv(r,c,3), r, c];
%         end
%     end
%     k = 5;
%     [IDX C] = kmeans(data, k, 'emptyaction', 'singleton');
%     [val, shadow_cluster] = min(C(:,2));
%     k_mask = vec2mat(IDX == shadow_cluster, s_im(2));
%     result_k_mask = im_hsv;
%     result_mask(:,:, 1) = im_hsv(:,:,1) .* k_mask;
%     result_mask(:,:, 2) = im_hsv(:,:,2) .* k_mask;
%     result_mask(:,:, 3) = im_hsv(:,:,3) .* k_mask;
%     figure, imshow(hsv2rgb(double(k_mask)))

%*************************************************************************%

% SHADOW REMOVAL: different methods
    
    % Method 1: ADDITIVE SHADOW REMOVAL
    result_additive = zeros(s_im);
    % compiting colour difference between the shadow/lit areas
    diff_red = light_avg_red - shadow_avg_red;
    diff_green = light_avg_green - shadow_avg_green;
    diff_blue = light_avg_blue - shadow_avg_blue;
    % adding the difference to the shadow pixels
    result_additive(:,:,1) = image(:,:,1) + smoothmask * diff_red;
    result_additive(:,:,2) = image(:,:,2) + smoothmask * diff_green;
    result_additive(:,:,3) = image(:,:,3) + smoothmask * diff_blue;
    
    %---------------------------------------------------------------------%
    
    % Method 2: BASIC , LIGHT MODEL BASED SHADOW REMOVAL
    result_basic_model = zeros(s_im);
    % computing ratio of shadow/lit area luminance
    ratio_red = light_avg_red/shadow_avg_red;
    ratio_green = light_avg_green/shadow_avg_green;
    ratio_blue = light_avg_blue/shadow_avg_blue;
    %
    result_basic_model(:,:,1) = (light_mask + shadow_mask.*ratio_red).*image(:,:,1);
    result_basic_model(:,:,2) = image(:,:,2).*light_mask + shadow_mask.*ratio_green.*image(:,:,2);
    result_basic_model(:,:,3) = image(:,:,3).*light_mask + shadow_mask.*ratio_blue.*image(:,:,3);
    
    %---------------------------------------------------------------------%
    
    % Method 3: ADVANCE, LIGHT MODEL BASED SHADOW REMOVAL
    result_enhanced_model = zeros(s_im);
    % computing ratio of the luminances of the directed, and global lights
    ratio_red = light_avg_red/shadow_avg_red - 1;
    ratio_green = light_avg_green/shadow_avg_green - 1;
    ratio_blue = light_avg_blue/shadow_avg_blue - 1;
    % applying shadow removal
    result_enhanced_model(:,:,1) = (ratio_red + 1)./((1-smoothmask)*ratio_red + 1).*image(:,:,1);
    result_enhanced_model(:,:,2) = (ratio_green + 1)./((1-smoothmask)*ratio_green + 1).*image(:,:,2);
    result_enhanced_model(:,:,3) = (ratio_blue + 1)./((1-smoothmask)*ratio_blue + 1).*image(:,:,3);
   
    %---------------------------------------------------------------------%
    
    % Method 4: COMBINED ADDITIVE AND LIGHT MODEL BASED SHADOW REMOVAL IN im_ycbcr COLOURSPACE
    % conversion to YCbCr colorspace
    im_ycbcr = rgb2ycbcr(image);
    % computing averade channel values in im_ycbcr space
    shadow_avg_y = sum(sum(im_ycbcr(:,:,1).*shadow_core)) / sum(sum(shadow_core));
    shadow_avg_cb = sum(sum(im_ycbcr(:,:,2).*shadow_core)) / sum(sum(shadow_core));
    shadow_avg_cr = sum(sum(im_ycbcr(:,:,3).*shadow_core)) / sum(sum(shadow_core));
    %
    litavg_y = sum(sum(im_ycbcr(:,:,1).*light_core)) / sum(sum(light_core));
    litavg_cb = sum(sum(im_ycbcr(:,:,2).*light_core)) / sum(sum(light_core));
    litavg_cr = sum(sum(im_ycbcr(:,:,3).*light_core)) / sum(sum(light_core));
    % computing ratio, and difference in im_ycbcr space
    diff_y = litavg_y - shadow_avg_y;
    diff_cb = litavg_cb - shadow_avg_cb;
    diff_cr = litavg_cr - shadow_avg_cr;

    ratio_y = litavg_y/shadow_avg_y - 1;
    ratio_cb = litavg_cb/shadow_avg_cb - 1;
    ratio_cr = litavg_cr/shadow_avg_cr - 1;
    % shadow correction: Y->additive, Cb&Cr-> basic light model
    aux_result_im_ycbcr = im_ycbcr;
    %(light_mask + shadow_mask.*ratio_red).*image(:,:,1);
    %(ratio_red + 1)./((1-smoothmask)*ratio_red + 1).*image(:,:,1);
    aux_result_im_ycbcr(:,:,1) = im_ycbcr(:,:,1) + shadow_mask * diff_y;
    %dont forget: aux_result_im_ycbcr(:,:,1) = im_ycbcr(:,:,1).*light_mask + shadow_mask.*ratio_y.*im_ycbcr(:,:,1);
    %(ratio_y + 1)./((1-smoothmask)*ratio_y+1).*im_ycbcr(:,:,1);
    aux_result_im_ycbcr(:,:,2) = (ratio_cb+1)./((1-smoothmask)*ratio_cb+1).*im_ycbcr(:,:,2);
    %im_ycbcr(:,:,2).*light_mask + shadow_mask.*ratio_cb.*im_ycbcr(:,:,2);
    aux_result_im_ycbcr(:,:,3) = (ratio_cr+1)./((1-smoothmask)*ratio_cr+1).*im_ycbcr(:,:,3);
    %im_ycbcr(:,:,3).*light_mask + shadow_mask.*ratio_cr.*im_ycbcr(:,:,3);
    % conversion back to rgb colourspace
    result_im_ycbcr = ycbcr2rgb(aux_result_im_ycbcr);
 
%*************************************************************************%

% SHOW RESULTS:
    
    % Show original image
    figure, imshow(image), title('Original Image')
    % Show Masks: Light, Shadow, Smooth
    figure,
    subplot(1,3,1), imshow(light_mask), title('Light Mask')
    subplot(1,3,2), imshow(shadow_mask), title('Shadow Mask')
    subplot(1,3,3), imshow(smoothmask), title('Smooth Mask')
    % Show result ADDITIVE, BASIC LIGHT MODEL, ENHANCED LIGHT MODEL, YCbCr methods
    figure, 
    subplot(2,2,1), imshow(result_additive), title('Shadow Removal: Additive method')
    subplot(2,2,2), imshow(result_basic_model), title('Shadow Removal: Basic light model method')
    subplot(2,2,3), imshow(result_enhanced_model), title('Shadow Removal: Enhanced light model method')
    subplot(2,2,4), imshow(result_im_ycbcr), title('Shadow Removal: YC_bC_r method')
