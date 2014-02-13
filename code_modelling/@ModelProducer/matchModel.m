function struc = matchModel( obj )
% fits the generic model to the speaker-specific anatomy

nRowTongMesh = 17;
nColTongueMesh = 13;

tongSurfMRI = obj.anatomicalStructures.tongueSurface;
nPointsTongSurfMRI = size(tongSurfMRI, 2);

styloidProcess = obj.landmarksTransformed.styloidProcess;

tongInsL = obj.landmarksTransformed.tongInsL;
tongInsH = obj.landmarksTransformed.tongInsH;
ANS_mri = obj.landmarksTransformed.ANS;
PNS_mri = obj.landmarksTransformed.PNS;

% Insertion points of the hyoglossus into the hyoid bone
hyoAGeneric = obj.modelGeneric.landmarks.hyoA;
hyoBGeneric = obj.modelGeneric.landmarks.hyoB;
hyoCGeneric = obj.modelGeneric.landmarks.hyoC;

lar_ar_mri = obj.anatomicalStructures.larynxArytenoid;
palate_mri = obj.anatomicalStructures.upperIncisorPalate;
pharynx_mri = obj.anatomicalStructures.backPharyngealWall;
tongue_lar_mri = obj.anatomicalStructures.tongueLarynx;
upperlip_mri = obj.anatomicalStructures.upperLip;
velum_mri = obj.anatomicalStructures.velum;

% generic tongue mesh at rest position
tongMeshGen = obj.modelGeneric.tongGrid; % Class PositionFrame
valTmp = getPositionOfNodeNumbers(tongMeshGen, 1:221);
X_repos = reshape(valTmp(1, :), nColTongueMesh, nRowTongMesh)';
Y_repos = reshape(valTmp(2, :), nColTongueMesh, nRowTongMesh)';

% tongue surface of YPM
xValsTongSurfGenMatrix = X_repos(:, nColTongueMesh); % x coordinates
yValsTongSurfGenMatrix = Y_repos(:, nColTongueMesh); % y coordinates
tongSurfGen = [xValsTongSurfGenMatrix'; yValsTongSurfGenMatrix'];
nPointsTongSurfGen = length(xValsTongSurfGenMatrix);

% Interpolation of the tongue contour of the target speaker in order to
% get a better matching of this contour starting from YPM's contour. We take
% 10 times more nodes for a better definition of the speaker-specific
% tongue contour
xValsTongSurgMRIOrig = ...
    spline(1:nPointsTongSurfMRI, tongSurfMRI(1, :), 1:1/10:nPointsTongSurfMRI);
yValsTongSurgMRIOrig = ...
    spline(1:nPointsTongSurfMRI, tongSurfMRI(2, :), 1:1/10:nPointsTongSurfMRI);

tongSurfMRI = [xValsTongSurgMRIOrig; yValsTongSurgMRIOrig];
nPointsTongSurfMRIOrig = length(xValsTongSurgMRIOrig);

% Plot the data around the generic average position ----------------------
figure
% Plot the generic tongue
for j = 1:nColTongueMesh
    for i = 1:nRowTongMesh-1
        plot([X_repos(i,j) X_repos(i+1,j)], ...
            [Y_repos(i,j) Y_repos(i+1,j)], ':r')
        hold on
    end
end
for i = 1:nRowTongMesh
    for j = 1:nColTongueMesh-1
        plot([X_repos(i,j) X_repos(i,j+1)], ...
            [Y_repos(i,j) Y_repos(i,j+1)], ':r')
    end
end

% draw in green the nodes of the generic tongue surface
plot(xValsTongSurfGenMatrix, yValsTongSurfGenMatrix,'*g')
hold on

% plot the interpolated MRI tongue surface
plot(tongSurfMRI(1, :), tongSurfMRI(2, :), 'b*', 'Linewidth', 2)
axis('equal')

% end plotting ------------------------------------------------------------


% computation of the piecewise length of the generic tongue contour
lenSegTongSurfGen = nan(1, nPointsTongSurfGen-1);
for k = 1:nPointsTongSurfGen-1
    lenSegTongSurfGen(k) = points_dist_nd (2, ...
        tongSurfGen(:, k), tongSurfGen(:, k+1));
end
lenTotTongSurfGen = sum(lenSegTongSurfGen);

% computation of the piecewise length of the mri tongue contour
lenSegTongSurfMRIOrig = nan(1, nPointsTongSurfMRIOrig-1);
for k = 1:nPointsTongSurfMRIOrig-1
    lenSegTongSurfMRIOrig(k) = points_dist_nd (2, ...
        tongSurfMRI(:, k), tongSurfMRI(:, k+1));
end
lenTotTongSurfMRI = sum(lenSegTongSurfMRIOrig);

% Computation (generic model) of the relative position of the nodes along 
% the tongue surface. The reference point is the first point of the
% surface located on the hyoid bone. The relative position of each surface node 
% is characterised by the ratio ratioRelPosGen of its distance to the 
% reference point divided by the total length of the tongue surface.

% for the first point the ratio is obviously 0
ratiosRelPosGen = nan(1, nPointsTongSurfGen);
ratiosRelPosGen(1) = 0;
for k = 2:nPointsTongSurfGen
    ratiosRelPosGen(k) = sum(lenSegTongSurfGen(1:k-1)) / lenTotTongSurfGen;
end

ratiosRelPosMRI = nan(1, nPointsTongSurfMRIOrig);
ratiosRelPosMRI(1) = 0;
for i = 2:nPointsTongSurfMRIOrig
    % Ratio for the other points on the contour
    ratiosRelPosMRI(i) = sum(lenSegTongSurfMRIOrig(1:i-1)) / lenTotTongSurfMRI;
end

% constructing the adapted tongue surface
% the matching process starts by aligning the first point of the adapted
% model (on the hyoid bone) with the first point of the tongue contour of
% the target speaker, and by aligning the tongue tip point of the adapted
% model with the last point of the tongue contour of the target speaker.



% Lowest point of the upper contour of the adapted model = Lowest point
% of the speaker specific tongue contour
x_new(1) = xValsTongSurgMRIOrig(1);
% Lowest point of the upper contour of the adapted model = Lowest point
% of the speaker specific tongue contour
y_new(1) = yValsTongSurgMRIOrig(1);
% Tongue tip point of the upper contour of the adapted model = Tongue tip
% point of the speaker specific tongue contour
x_new(nPointsTongSurfGen) = xValsTongSurgMRIOrig(nPointsTongSurfMRIOrig);
% Tongue tip point of the upper contour of the adapted model = Tongue tip
% point of the speaker specific tongue contour
y_new(nPointsTongSurfGen) = yValsTongSurgMRIOrig(nPointsTongSurfMRIOrig);




% To match the upper contour of the adapted model with the tongue contour of
% the target subject each node nYPM of the contour of YPM is projected onto
% the point nREF of the tongue contour of the target speaker, for which the
% ratio prop_elem_ref gives the best approximation of the ratio
% prop_elem_mod calculated for node nYPM.
jlast = 1;
for k = 2:nPointsTongSurfGen-1
    j = jlast;
    while (j < nPointsTongSurfMRIOrig)
        j = j + 1;
        if ratiosRelPosMRI(j-1) < ratiosRelPosGen(k) && ratiosRelPosMRI(j) >= ratiosRelPosGen(k)
            jlast = j;
            x_new(k) = xValsTongSurgMRIOrig(j);
            y_new(k) = yValsTongSurgMRIOrig(j);
            j = nPointsTongSurfMRIOrig;
        end
    end
end



% plot adapted tongue surface and shows displacement from generic
plot(x_new, y_new, 'or', 'Linewidth', 2)
for i = 1:nPointsTongSurfGen
    plot([xValsTongSurfGenMatrix(i) x_new(i)], [yValsTongSurfGenMatrix(i) y_new(i)], ':g')
end




% the nodes on the adapted tongue contour correspond to the nodes of
% the tongue mesh at rest (ncol = 13)
X_repos_new(1:17, nColTongueMesh) = x_new;
Y_repos_new(1:17, nColTongueMesh) = y_new;

% Lowest insertion point of the lower incisor
X_repos_new(1,1) = tongInsL(1);
Y_repos_new(1,1) = tongInsL(2);

% Upper insertion on the incisor
X_repos_new(nRowTongMesh,1) = tongInsH(1);
Y_repos_new(nRowTongMesh,1) = tongInsH(2);





% load generic lower incisor contour
% height_bone_int, index_height_bone_int and index_height_bone_ext been added
% in this file in February 2011 (Pascal)
strucTeethLips = load('standard_teeth_lips.mat');
teethLowerStandard = strucTeethLips.lower_teeth_standard;
nPointsteethLowerStandard = length(teethLowerStandard(1, :));
index_height_bone_int = strucTeethLips.index_height_bone_int;
index_height_bone_ext = strucTeethLips.index_height_bone_ext;
lowlip_standard = strucTeethLips.lowlip_standard;
index_intersect_lips_tooth = strucTeethLips.index_intersect_lips_tooth;
index_end_upper_inc = strucTeethLips.index_end_upper_inc;

% calculate inclination angle of the incisor
% distance between the transformed mri lowest and highest insertion points
dist_inc_new = sqrt((tongInsH(1)-tongInsL(1))^2 + (tongInsH(2) - tongInsL(2))^2);
% distance between the generic lowest and highest insertion points
dist_inc_mod = sqrt((teethLowerStandard(1, index_height_bone_int) - teethLowerStandard(1,end))^2 +...
    (teethLowerStandard(2, index_height_bone_int) - teethLowerStandard(2,end))^2);
% distance ratio for the incisor between the length in the adapted model
% and the length in YPM
rapport_dist_inc = dist_inc_new/dist_inc_mod;







% Sign of the vertical difference between the lowest and highest
% insertion points on the incisor in the adapted model
signe_inc_new = sign(tongInsH(2)-tongInsL(2));
% Sign of the vertical difference between the lowest and highest
% insertion points on the incisor in the generic model
signe_inc_mod = sign(teethLowerStandard(2, index_height_bone_int) - teethLowerStandard(2,end));
% Angle of the line joining the lowest and highest insertion points on the
% incisor in the adapted model
angle_inc_new = signe_inc_new*acos((tongInsH(1)-tongInsL(1))/dist_inc_new);
% Angle of the line joining the lowest and highest insertion points on
% the incisor in YPM
angle_inc_mod = signe_inc_mod*acos((teethLowerStandard(1,index_height_bone_int)-teethLowerStandard(1,end))/dist_inc_mod);
% The difference between these two angles is a measure of the global
% rotation of the incisor
angle_inc_rotat = angle_inc_new - angle_inc_mod;
% Characteristics of the insertion points of the tongue on the generic incisor
dist_inc = nan(1, nRowTongMesh-1);
signe_inc = nan(1, nRowTongMesh-1);
angle_inc = nan(1, nRowTongMesh-1);
for j = 2:nRowTongMesh-1
    % Distance between the current insertion point and the lowest insertion
    % point in YPM
    dist_inc(j) = sqrt((X_repos(j,1)-X_repos(1,1))^2 + (Y_repos(j,1)-Y_repos(1,1))^2);
    % Sign of the vertical difference between the current insertion
    % point and the lowest insertion point in the original model YPM
    signe_inc(j) = sign((Y_repos(j,1) - Y_repos(1,1)));
    % Angle of the line joining the current insertion
    % point and the lowest insertion point in the original model YPM
    angle_inc(j) = signe_inc(j) * abs(acos((X_repos(j,1)-X_repos(1,1))/dist_inc(j)));
end

% teeth characteristics in the adopted model
[~, ind_max_height_teeth] = max(teethLowerStandard(2,:));
dist_teeth_int(nPointsteethLowerStandard) = 0;
angle_teeth_int(nPointsteethLowerStandard) = 0;

for j = ind_max_height_teeth:nPointsteethLowerStandard-1
    % Distance between the current point and the lowest insertion point in
    % YPM
    dist_teeth_int(j) = sqrt((teethLowerStandard(1,j) - teethLowerStandard(1,end))^2 + ...
        (teethLowerStandard(2,j) - teethLowerStandard(2,end))^2);
    % Angle of the line joining the current insertion point and the lowest
    % insertion point in YPM
    angle_teeth_int(j) = abs(acos((teethLowerStandard(1,j) - ...
        teethLowerStandard(1, end)) / dist_teeth_int(j)));
end

x_teeth_ext_int = nan(1, index_height_bone_ext);
y_teeth_ext_int = nan(1, index_height_bone_ext);
for j = 1:index_height_bone_ext
    % Distance in x and y between the current point and the corresponding
    % point on the internal contour
    x_teeth_ext_int(j) = teethLowerStandard(1,j) - teethLowerStandard(1,end-j+1);
    y_teeth_ext_int(j) = teethLowerStandard(2,j) - teethLowerStandard(2,end-j+1);
end

% positioning of the lower incisor in the adapted model. New insertions of the
% tongue model on the incisors (all the points are located between the lowest
% and the highest insertion points) after rotation
for j = index_height_bone_int+1:nPointsteethLowerStandard-1
    % Angle of the line joining the current point and the lowest insertion
    % point in the adapted model after a rotation equal to the global rotation
    % of the incisor
    angle_teeth_final_int(j) = angle_teeth_int(j) + angle_inc_rotat;
    % Position of the corresponding insertion point in the adapted model
    new_dist = rapport_dist_inc * dist_teeth_int(j);
    dents_inf_new(1,j) = teethLowerStandard(1,end) + ...
        rapport_dist_inc * dist_teeth_int(j) * cos(angle_teeth_final_int(j));
    dents_inf_new(2,j) = teethLowerStandard(2,end) + ...
        rapport_dist_inc * dist_teeth_int(j) * sin(angle_teeth_final_int(j));
end
dents_inf_new(1, nPointsteethLowerStandard) = 0;
dents_inf_new(2, nPointsteethLowerStandard) = 0;

dents_inf_new(1, index_height_bone_int) = tongInsH(1)-tongInsL(1);
dents_inf_new(2, index_height_bone_int) = tongInsH(2)-tongInsL(2);

for j = 1:index_height_bone_ext
    dents_inf_new(1,j) = x_teeth_ext_int(j) + dents_inf_new(1,end-j+1);
    dents_inf_new(2,j) = y_teeth_ext_int(j) + dents_inf_new(2,end-j+1);
end

for j = ind_max_height_teeth:index_height_bone_int-1
    dents_inf_new(1,j) = dents_inf_new(1,index_height_bone_int) + min(1,rapport_dist_inc) *...
        (teethLowerStandard(1,j) - teethLowerStandard(1,index_height_bone_int));
    dents_inf_new(2,j) = dents_inf_new(2,index_height_bone_int) + min(1,rapport_dist_inc) *...
        (teethLowerStandard(2,j) - teethLowerStandard(2,index_height_bone_int));
end

for j = index_height_bone_ext+2:ind_max_height_teeth-1
    dents_inf_new(1,j) = dents_inf_new(1,index_height_bone_int) + min(1,rapport_dist_inc) *...
        (teethLowerStandard(1,j) - teethLowerStandard(1,index_height_bone_int));
    dents_inf_new(2,j) = dents_inf_new(2,index_height_bone_int) + min(1,rapport_dist_inc) *...
        (teethLowerStandard(2,j) - teethLowerStandard(2,index_height_bone_int));
end

dents_inf_new(1,index_height_bone_ext+1) = mean([dents_inf_new(1,index_height_bone_ext) ...
    dents_inf_new(1, index_height_bone_ext + 2)]);

dents_inf_new(2,index_height_bone_ext+1) = mean([dents_inf_new(2,index_height_bone_ext) ...
    dents_inf_new(2, index_height_bone_ext+2)]);

dents_inf_new(1,:) = X_repos_new(1,1) + dents_inf_new(1,:);
dents_inf_new(2,:) = Y_repos_new(1,1) + dents_inf_new(2,:);


% first (lowest) 3 mesh lines
% devide space between teeth last two teeth points into two sections

lineSegTmp = dents_inf_new(1:2, end:-1:end-1);
ptsTmp = polyline_points_nd(2, 2, lineSegTmp, 3);

X_repos_new(2, 1) = ptsTmp(1, 2);
Y_repos_new(2, 1) = ptsTmp(2, 2);

X_repos_new(3, 1) = ptsTmp(1, 3);
Y_repos_new(3, 1) = ptsTmp(2, 3);


% second section (2/3)
lineSegTmp = dents_inf_new(1:2, end-1:-1:end-2);
ptsTmp = polyline_points_nd(2, 2, lineSegTmp, 7);

X_repos_new(4, 1) = ptsTmp(1, 2);
Y_repos_new(4, 1) = ptsTmp(2, 2);

X_repos_new(5, 1) = ptsTmp(1, 3);
Y_repos_new(5, 1) = ptsTmp(2, 3);

X_repos_new(6, 1) = ptsTmp(1, 4);
Y_repos_new(6, 1) = ptsTmp(2, 4);

X_repos_new(7, 1) = ptsTmp(1, 5);
Y_repos_new(7, 1) = ptsTmp(2, 5);

X_repos_new(8, 1) = ptsTmp(1, 6);
Y_repos_new(8, 1) = ptsTmp(2, 6);

X_repos_new(9, 1) = ptsTmp(1, 7);
Y_repos_new(9, 1) = ptsTmp(2, 7);

% third section (3/3)
lineSegTmp = dents_inf_new(1:2, end-2:-1:end-3);
ptsTmp = polyline_points_nd(2, 2, lineSegTmp, 9);

X_repos_new(10, 1) = ptsTmp(1, 2);
Y_repos_new(10, 1) = ptsTmp(2, 2);

X_repos_new(11, 1) = ptsTmp(1, 3);
Y_repos_new(11, 1) = ptsTmp(2, 3);

X_repos_new(12, 1) = ptsTmp(1, 4);
Y_repos_new(12, 1) = ptsTmp(2, 4);

X_repos_new(13, 1) = ptsTmp(1, 5);
Y_repos_new(13, 1) = ptsTmp(2, 5);

X_repos_new(14, 1) = ptsTmp(1, 6);
Y_repos_new(14, 1) = ptsTmp(2, 6);

X_repos_new(15, 1) = ptsTmp(1, 7);
Y_repos_new(15, 1) = ptsTmp(2, 7);

X_repos_new(16, 1) = ptsTmp(1, 8);
Y_repos_new(16, 1) = ptsTmp(2, 8);

% 17th point is assigned elsewhere ...


% Changes for the lower lip
lowlip_new(1,:) = min(1,rapport_dist_inc) * (lowlip_standard(1,:) - teethLowerStandard(1,index_intersect_lips_tooth)) +...
    dents_inf_new(1,index_intersect_lips_tooth);
lowlip_new(2,:) = min(1,rapport_dist_inc) * (lowlip_standard(2,:) - teethLowerStandard(2,index_intersect_lips_tooth)) +...
    dents_inf_new(2,index_intersect_lips_tooth);








% Computation of the internal nodes of the adapted tongue model
for i = 1:nRowTongMesh
    % Distance between the node on the upper contour of the adapted model and
    % the corresponding insertion nodes on the incisor
    dist_new = sqrt((X_repos_new(i,nColTongueMesh) - X_repos_new(i,1))^2 + (Y_repos_new(i,nColTongueMesh) - Y_repos_new(i,1))^2);
    % Distance between the node on the upper contour of YPM and the
    % corresponding insertion nodes on the incisor
    dist_mod = sqrt((X_repos(i,nColTongueMesh)-X_repos(i,1))^2+(Y_repos(i,nColTongueMesh)-Y_repos(i,1))^2);
    % Distance ratio for the current line between the adapted model and YPM
    rapport_dist = dist_new/dist_mod;
    % Sign of the vertical difference between the node on the upper contour
    % of the adapted model and the corresponding insertion nodes on the incisor
    signe_new = sign((Y_repos_new(i,nColTongueMesh)-Y_repos_new(i,1)));
    % Sign of the vertical difference between the node on the upper contour of
    % YPM and the corresponding insertion nodes on the incisor
    signe_mod = sign((Y_repos(i,nColTongueMesh)-Y_repos(i,1)));
    % Angle of the line joining the node on the upper contour of adapted model
    % and the corresponding insertion nodes on the incisor
    angle_new = signe_new*acos((X_repos_new(i, nColTongueMesh) - X_repos_new(i,1))/dist_new);
    % Angle of the line joining the node on the upper contour of YPM and the
    % corresponding insertion nodes on the incisor
    angle_mod = signe_mod*acos((X_repos(i,nColTongueMesh)-X_repos(i,1))/dist_mod);
    % The difference between these two angles is a measure of the global
    % rotation of the current line
    angle_rotat = angle_new - angle_mod;
    
    % Computation of the parameter used to define the hyoid bone in the
    % adapted model
    if (i == 1)
        % In order to be able to predict the hyoid bone position in the adapted
        % model we take into account the rapport_dist and angle_rotat
        % parameters found for the 1st line (corresponding to the bottom of the
        % tongue)
        rapport_dist_hyoid = rapport_dist;
        
        % The line joining the lowest insertion point of the tongue
        % on the incisor and the lowest point of hyoid bone (X1,Y1) will be
        % rotated in the adapted model by the same angle as the lowest
        % line of the mesh (see below)
        angle_rotat_hyoid = angle_rotat;
    end
    % Plot the nodes on the lowest line in the adapted model
    plot(X_repos_new(i, 1), Y_repos_new(i, 1), '+r', 'Linewidth',2)
    
    plot(tongInsH(1), tongInsH(2),'or','Linewidth',3)
    
    
    distTmp = nan(1, nColTongueMesh-1);
    signTmp = nan(1, nColTongueMesh-1);
    angle_intern = nan(1, nColTongueMesh-1);
    angle_final = nan(1, nColTongueMesh-1);
    for j = 2:nColTongueMesh-1
        % Now we consider each internal node of the current line separately
        % Distance between this node and the corresponding insertion node
        % on the incisor in the original tongue model (YPM)
        distTmp(j) = sqrt((X_repos(i,j)-X_repos(i,1))^2+(Y_repos(i,j)-Y_repos(i,1))^2);
        % Sign of the vertical difference between this node and the
        % corresponding insertion node on the incisor in the generic model (YPM)
        signTmp(j) = sign((Y_repos(i,j)-Y_repos(i,1)));
        % Angle of the line joining this node and the corresponding insertion
        % node on the incisor in YPM
        angle_intern(j) = signTmp(j)*abs(acos((X_repos(i,j)-X_repos(i,1))/distTmp(j)));
        % Angle of the line joining this node and the corresponding insertion
        % node on the incisor in the adapted model after a rotation equal to
        % the global rotation of the current line
        angle_final(j) = angle_intern(j) + angle_rotat;
        
        % Position of the corresponding node in the adapted model
        X_repos_new(i, j) = X_repos_new(i, 1) + rapport_dist*distTmp(j)*cos(angle_final(j));
        Y_repos_new(i, j) = Y_repos_new(i, 1) + rapport_dist*distTmp(j)*sin(angle_final(j));
        
        plot(X_repos(i, j), Y_repos(i, j), 'ob')
        % Plot the nodes on the corresponding line in the adapted model
        plot(X_repos_new(i,j), Y_repos_new(i,j), '+r', 'Linewidth', 2)
        
    end
    
end

% Plot the new mesh
for j=1:nColTongueMesh
    for i=1:nRowTongMesh-1
        plot([X_repos_new(i,j) X_repos_new(i+1,j)], ...
            [Y_repos_new(i,j) Y_repos_new(i+1,j)], 'r')
    end
end
for i=1:nRowTongMesh
    for j=1:nColTongueMesh-1
        plot([X_repos_new(i,j) X_repos_new(i,j+1)], ...
            [Y_repos_new(i,j) Y_repos_new(i,j+1)], 'r')
    end
end
plot(dents_inf_new(1,:), dents_inf_new(2,:),'g')
plot(dents_inf_new(1,:), dents_inf_new(2,:),'og')
plot(lowlip_new(1,:),lowlip_new(2,:),'g')

% Change upper incisor and upper lip
palate_new_orig(1) = palate_mri(1,1);
palate_new_orig(2) = palate_mri(2,1);
for j=1:index_end_upper_inc
    palate_mri(1,j) = palate_mri(1,index_end_upper_inc) + ...
        min(1,rapport_dist_inc)*(palate_mri(1,j) - ...
        palate_mri(1, index_end_upper_inc));
    palate_mri(2,j) = palate_mri(2,index_end_upper_inc) + ...
        min(1,rapport_dist_inc)*(palate_mri(2,j) - ...
        palate_mri(2, index_end_upper_inc));
end
upperlip_mri(1,:) = min(1,rapport_dist_inc*1.1) * ...
    (upperlip_mri(1,:) - palate_new_orig(1)) + palate_mri(1,1);
upperlip_mri(2,:) = min(1,rapport_dist_inc*1.1) * ...
    (upperlip_mri(2,:) - palate_new_orig(2)) + palate_mri(2,1);

% Computation of the 3 points for the hyoglossus insertion on the hyoid bone
% in the adapted model
% Distance between the first point of the hyoid bone (X1,Y1) and the lowest
% insertion point of the tongue on the incisor in the original model (YPM)
dist1 = sqrt((hyoAGeneric(1) - X_repos(1,1))^2 + (hyoAGeneric(2) - Y_repos(1,1))^2);
% Sign of the vertical difference between the first point of the hyoid
% bone (X1,Y1) and the lowest insertion point of the tongue on the incisor in
% the original model (YPM)
signe1 = sign((hyoAGeneric(2) - Y_repos(1,1)));
% Angle of the line joining the first point of the hyoid bone (X1,Y1) and the
% lowest insertion point of the tongue on the incisor in the generic model (YPM)
angle_hyoid1 = signe1 * abs(acos((hyoAGeneric(1) - X_repos(1,1)) / dist1));
% Angle of the line joining the first point of the hyoid bone (X1_new,Y1_new)
% and the lowest insertion point of the tongue on the incisor in the adapted
% model after a rotation with an angle angle_rotat_hyoid equal to the rotation
% of the lowest line of the mesh (see above)
angle_final_hyoid1 = angle_hyoid1 + angle_rotat_hyoid;

% Position of the corresponding point in the adapted model
X1_new = X_repos_new(1,1) + rapport_dist_hyoid*dist1*cos(angle_final_hyoid1);
Y1_new = Y_repos_new(1,1) + rapport_dist_hyoid*dist1*sin(angle_final_hyoid1);

% The other points of the hyoid bone will be defined from the points of the
% hyoid bone in the original model (YPM)
X2_new = X1_new + hyoBGeneric(1) - hyoAGeneric(1);
Y2_new = Y1_new + hyoBGeneric(2) - hyoAGeneric(2);

X3_new = X1_new + hyoCGeneric(1) - hyoAGeneric(1);
Y3_new = Y1_new + hyoCGeneric(2) - hyoAGeneric(2);


structTemp = load ('data_palais_repos.mat');

plot(structTemp.dents_inf(1,:), structTemp.dents_inf(2,:),':r')
plot(structTemp.lowlip(1,:), structTemp.lowlip(2,:),':r')

title('Matching in sagittal plane')


% store data in a structure
struc.landmarks.styloidProcess = styloidProcess;
struc.landmarks.condyle = [styloidProcess(1); styloidProcess(2)+8];
struc.landmarks.ANS(1:2, 1) = ANS_mri;
struc.landmarks.PNS(1:2, 1) = PNS_mri;
struc.landmarks.hyo1 = [X1_new; Y1_new];
struc.landmarks.hyo2 = [X2_new; Y2_new];
struc.landmarks.hyo3 = [X3_new; Y3_new];
struc.landmarks.origin = obj.modelGeneric.landmarks.origin;

% to be inspected .... \todo
struc.landmarks.incisor_up_mri = [tongInsH(1); tongInsH(2)];
struc.landmarks.incisor_low_mri = [tongInsL(1); tongInsL(2)];

% store data related to the adopted vocal tract contour
% anatomical structures are not affected by adaptation
struc.structures.upperLip = upperlip_mri;
struc.structures.upperIncisorPalate = palate_mri;
struc.structures.velum = velum_mri;
struc.structures.backPharyngealWall = pharynx_mri;
struc.structures.larynxArytenoid = lar_ar_mri;
struc.structures.tongueLarynx = tongue_lar_mri;
struc.structures.lowerIncisor = dents_inf_new;
struc.structures.lowerLip = lowlip_new;

% Save the adopted tongue rest position
struc.tongGrid.x = reshape(X_repos_new', 1, 221);
struc.tongGrid.y = reshape(Y_repos_new', 1, 221);

end

