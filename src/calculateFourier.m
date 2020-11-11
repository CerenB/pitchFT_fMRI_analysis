function [TargetSNR, TargetPhase, TargetSNRsigned, tSNR] = calculateFourier(X, Xraw, ...
                                                                            TargetFrequency, ...
                                                                            BinSize, Thresh, ...
                                                                            histBin)
    % Fourier analysis of fMRI time series data, returns the SNR at a given
    %        frequency for each voxel
    %
    % Xiaoqing Gao, Dec 6, 2017, Louvain-la-Neuve, dr.x.gao@gmail.com
    %
    % Input data:
    %        1.X: rows are MRI measurements (at time points); columns are
    %          voxels; Xraw, raw data, no linear detrending

    %        2.TargetFrequency: the frequency bin (ordinal number) of the
    %          target frequency

    %        3.BinSize: number of frequency bins surronding the target
    %          frequency bin (e.g., 40 means ?20 bins, with a gap of 1 bin from
    %          the target frequncy). These neighbouring frequencies are treaed as
    %          noise.

    %        4.Thresh: a threshold value (e.g., 3.719). The distribution of
    %          the phase values of the voxels above this threshold value are
    %          used to define activation/deactivation.

    %        5.histBin: initial number of bins used for calculating the histogram
    %          of phase distribution for defining activation/deactivation, if
    %          there are more than one bins with maximum count, histBin+1
    %
    % Output: 1. TargetSNR: SNR (z-score) at the target frequency for each
    %           voxels

    %        2. TargetPhase: Fourier phase of the target frequency for each
    %           voxel

    %        3. TargetSNRsigned: Activation (+)/deactivation (-) defined by
    %           phase values and applied to the SNR values for each voxel. This
    %           can be used to generate a signed map.

    %        4. tSNR

    % Steps of the analysis
    % 1. FFT of the time series

    tSNR = mean(Xraw) ./ std(Xraw);

    FT = fft(X);

    % 2. define noise frequencies based on TargetFrequency and BinSize with a
    % gap of 1
    gap = 1;
    NoiseFs = [(TargetFrequency - BinSize / 2 - gap): ...
               (TargetFrequency - 1 - gap) (TargetFrequency + 1 + gap): ...
               (TargetFrequency + BinSize / 2 + gap)];

    % 3. calculate the mean and SD of the amplitudes of the noise frequencies
    FTNoise = FT(NoiseFs, :);
    AmpNoise = abs(FTNoise);
    NoiseMean = mean(AmpNoise, 1);
    NoiseSD = std(AmpNoise, 0, 1);

    % 4. calculate SNR (z-score) of the target frequency based on the mean and SD of the
    % noise frequencies
    TargetSNR = (abs(FT(TargetFrequency, :)) - NoiseMean) ./ NoiseSD;

    % 5. using the distribution of phase of the target frequency to define the sign
    TargetPhase = angle(FT(TargetFrequency, :));

    % 5.1 find the peak of the distribution of positive phase
    % It assums that in the experiment, stimulus onset is at 0 phase
    TargetPhaseP = TargetPhase(TargetPhase > 0); % positive phase values
    while 1
        [n, x] = hist(TargetPhaseP(TargetSNR(TargetPhase > 0) > Thresh), ...
                      histBin);
        xcenter = x(n == max(n));
        if length(xcenter) > 1
            histBin = histBin + 1;
        else
            break
        end
    end

    % 5.2 assign the peak phase ? pi/2 to be 1 and the others to be -1
    PhaseDiff = abs(TargetPhase - xcenter);
    PhaseIndex = zeros(size(PhaseDiff));
    PhaseIndex(PhaseDiff <= (pi / 2)) = 1;
    PhaseIndex(PhaseDiff > (pi / 2)) = -1;

    % 5.3 apply sign to target SNR
    TargetSNRsigned = TargetSNR .* PhaseIndex;
