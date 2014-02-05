classdef SpeakerImaging
    %create speaker model based on landmarks derived from midsagittal MRI image
    
    properties
        
        princInvestigator = ''; % abbr. for PI during imaging
        name = '';              % abbr. for speaker during imaging
        phoneme = '';           % phoneme produced during imaging
        
        landmarks = [];
        landmarksDerivedMorpho = [];
        landmarksDerivedGrid = [];
        
        measuresMorphology = [];
        measuresTongueShape = [];
        measuresConstriction = [];
        UserData = [];
        
        semipolarGrid = [];
        gridZoning = [];
        
        contours = [];
        filteredContours = [];
        
        sliceInfo = '';
        xdataSlice = [];
        ydataSlice = [];
        sliceData = [];
        sliceSegmentationData = [];
    end
    
    properties (Access = private)
        
        slicePosition3D = [];   % 3D position of 2D slice (if available)
        
    end
    
    
    methods
        
        function obj = SpeakerImaging(mat)
            
            obj.princInvestigator = mat.princInvestigator;
            obj.name = mat.speakerName;
            obj.phoneme = mat.phonLab;
            
            obj.slicePosition3D = mat.ptPhysio.Lx(1);
            
            % assign landmarks
            fieldnamesTmp = fieldnames(mat.ptPhysio);
            for k = 1:length(fieldnamesTmp)
                ptTmp = mat.ptPhysio.(fieldnamesTmp{k});
                obj.landmarks.(fieldnamesTmp{k}) = ptTmp(2:3)';
            end
            
            obj.landmarksDerivedMorpho = deriveLandmarksMorpho(obj);
            obj.landmarksDerivedGrid = deriveLandmarksGrid(obj);
            
            obj.measuresMorphology = determineMeasuresMorphology(obj);
            
            obj.semipolarGrid = determineSemipolarGrid(obj);
            obj.gridZoning = zoneGridIntoAnatomicalRegions(obj);
            
            obj.sliceInfo = mat.sliceInfo;
            obj.xdataSlice = [0 obj.sliceInfo.PixelDimensions(2)*obj.sliceInfo.Dimensions(2)];
            obj.ydataSlice = [obj.sliceInfo.PixelDimensions(3)*obj.sliceInfo.Dimensions(3) 0];
            obj.sliceData = mat.sliceData;
            obj.sliceSegmentationData = mat.sliceSegmentationData;
            
            obj.contours = determineOutlineFromSegmentation(obj);
            obj.filteredContours = determineFilteredContour(obj);
            
        end
        
        [] = initPlotFigure(obj, imageFlag);

        [] = plotLandmarks(obj, col);
        [] = plotLandmarksDerived(obj, col);
        [] = plotMeasureMorphology(obj, featureName, col);
        [] = plotMeasureTongueShape(obj, featureName, col);
        [] = plotMeasureConstriction(obj, featureName, col);
        [] = plotSemipolarGrid(obj, col, nbsOfGrdLines);
        [] = plotContours(obj, flagBspline, col);
        
        obj = resampleMidSagittSlice(obj, targetPixelWidth, targetPixelHeight);
        obj = normalizeMidSagittSlice(obj);

        obj = determineMeasuresTongueShape(obj);
        obj = determineMeasuresConstriction(obj);
        
        matModelTarget = convertToRawModelFormat(obj)
        
    end
    
    methods (Access = private)
           
        ptPhysioDerived = deriveLandmarksMorpho(obj);
        ptPhysioDerived = deriveLandmarksGrid(obj);
        measuresMorphology = determineMeasuresMorphology(obj);
        grid = determineSemipolarGrid(obj);
        gridZoning = zoneGridIntoAnatomicalRegions(obj);
        contours = determineOutlineFromSegmentation(obj);
        filteredContours = determineFilteredContour(obj);

        landmarks = exportLandmarksToModelFormat(obj)
        structures = exportStructuresToModelFormat(obj);

        
    end

    methods (Static)
        
        [val, UserData] = determineCurvatureInvRadius(ptStart, ptMid, ptEnd);
        [val, UserData] = determineCurvatureQuadCoeff(innerPtPart);
        [val, UserData] = determineTongueLength(innerPtPart, indTongStart, indTongEnd);
        [val, UserData] = determineRelConstrHeight(landmarksDerivedMorpho, ...
            innerPtGrdlineConstr, outerPtGrdlineConstr, lenVertAbs);

        [valMin, indMin] = calculateMinBetweenContours(innerCont, outerCont);
        indBending = calcGridlineOfBending(innerPt, outerPt, ptCircleMidpoint, ptNPW_d);
        
    end
    
end

