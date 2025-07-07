clc; clear; close all;

% Given: 25x: 504 pixels = 2000 nanometers
% Given: 10x: 504 pixels = 5000 nanometers

% Step 1: Read the image and convert it to grayscale (if necessary)
img = imread('PS B_0009.tif');  % Load the image
%img = imcrop(img);
grayImg = im2gray(img);  % Convert to grayscale

% Step 2: Apply thresholding to create a binary image
binaryImg = imbinarize(grayImg,0.3); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Step 3: Invert the binary image to make white areas as particles
%binaryImg = imcomplement(binaryImg);  % Invert the black and white areas

% Step 4: Use morphological operations to clean up the binary image
binaryImg = imopen(binaryImg, strel('disk', 2));  % Remove small noise

% Optional Smoothing (Gaussian filtering to reduce noise)
binaryImg = imgaussfilt(double(binaryImg), 1);  % Apply Gaussian filter with sigma=2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
binaryImg = imbinarize(binaryImg);  % Re-binarize after smoothing

% Step 5: Use Distance Transform and Watershed for separation of touching particles
D = -bwdist(~binaryImg);  % Compute the distance transform
D = imhmin(D, 1);  % Control the depth of minima (adjust this value to control separation)

% Apply watershed
L = watershed(D);  % Apply watershed transform
binaryImg(L == 0) = 0;  % Set watershed ridges to background
figure;
imshow(binaryImg);
hold off;

%%
% Step 6: Detect individual particles using connected components
cc = bwconncomp(binaryImg);  % Detect connected components (particles)

% Step 7: Measure particle properties, including centroids, area, and perimeter for circularity
stats = regionprops(cc, 'EquivDiameter', 'Centroid', 'Area', 'Perimeter');  % Measure diameters, centroids, area, and perimeter

% Extract diameters in pixels and other properties
diameters_pixels = [stats.EquivDiameter];
centroids = cat(1, stats.Centroid);  % Extract centroids (x, y coordinates)
areas = [stats.Area];  % Extract areas
perimeters = [stats.Perimeter];  % Extract perimeters

% Step 8: Calculate circularity
circularity = (4 * pi * areas) ./ (perimeters .^ 2);  % Circularity formula

% Step 9: Filter particles based on circularity and diameter (diameters >= 100 nm)
min_diameter_nm = 150;  % Set the threshold for minimum diameter
max_diameter_nm = 260;
circularity_threshold_min = 0.95;  % Set a threshold for minimum circularity (adjust as needed) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
circularity_threshold_max = 1.05; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convert diameters to nanometers
scaling_factor = 2000 / 504;  % nanometers per pixel %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diameters_nm = diameters_pixels * scaling_factor;  % Convert diameters to nanometers

% Get indices of valid particles (based on circularity and diameter)
valid_idx = (diameters_nm >= min_diameter_nm) & (diameters_nm <= max_diameter_nm) & (circularity >= circularity_threshold_min) & (circularity <= circularity_threshold_max);

% Keep only valid data
diameters_nm = diameters_nm(valid_idx);  % Filter diameters
centroids = centroids(valid_idx, :);  % Filter centroids
circularity = circularity(valid_idx);  % Filter circularity

% Step 11: Define the bin edges for 10 nm intervals
binEdges = 140:5:260;  % Bins from 150 nm to 220 nm with 10 nm intervals

% Step 2: Create the figure
figure;
yyaxis left  % Left y-axis for Frequency (Counts)

% Step 3: Plot the size distribution in nanometers as a histogram (Counts)
h = histogram(diameters_nm, binEdges);  % Plot histogram with default counts
title('Particle Size Distribution');
xlabel('Diameter (nm)');
ylabel('Counts');  % Label for the left y-axis (Counts)

%%

% Step 1: Create a label matrix for visualization based on particle sizes
labeledImage = labelmatrix(cc);  % Assign labels to each connected component

% Step 2: Initialize an empty RGB image for visualization
RGB_label = zeros(size(labeledImage, 1), size(labeledImage, 2), 3);

% Step 3: Define the size thresholds for coloring
redThreshold = 220;   % Red for > 220 nm
greenThresholdMin = 185;   % Green for 185~220 nm
greenThresholdMax = 220;   % Upper limit for Green
blueThreshold = 185;   % Blue for < 185 nm

% Step 4: Loop through each particle and assign colors based on its size
new_index=0; R_num=0; G_num=0; B_num=0;
for i = 1:length(valid_idx)
    % Get the label index for the current particle
    if valid_idx(i) == 1 
        label = i;  % valid_idx holds the indices of the valid particles
        new_index=new_index+1;
        % Find all pixels corresponding to the current label
        [rows, cols] = find(labeledImage == label);
        
        % Assign color based on the particle size
        if diameters_nm(new_index) > redThreshold
            % Red for particles > 220 nm
            color = [255, 80, 130]/255;  % RGB for red
            R_num=R_num+1;
        elseif diameters_nm(new_index) >= greenThresholdMin && diameters_nm(new_index) <= greenThresholdMax
            % Green for particles between 185 and 220 nm
            color = [110, 250, 130]/255;  % RGB for green
            G_num=G_num+1;
        else
            % Blue for particles < 185 nm
            color = [120, 170, 255]/255;  % RGB for blue
            B_num=B_num+1;
        end
        
        % Color the corresponding pixels in the RGB label matrix
        for j = 1:length(rows)
            RGB_label(rows(j), cols(j), :) = color;
        end
    end
end
Total_num = R_num + G_num + B_num;
% Step 5: Display the RGB labeled image with three-color classification
figure;
imshow(RGB_label);
plot(centroids(:,1), centroids(:,2), 'w+', 'MarkerSize', 5, 'LineWidth', 1);  % Plot the centroids
hold off;
% No need for colorbar since only three distinct colors are used
