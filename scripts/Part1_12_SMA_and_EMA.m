file_names = {'HDFCBANK', 'ICICIBANK', 'INDUSINDBK', 'KOTAKBANK'};          % All the datasets.
current_file = file_names{1};                                               % Choosing dataset. Change it for every dataset.                          
data = readtable(strcat('../datasets/', current_file, '.csv'));             % Reading from csv file.
vwap = data.VWAP;               % VWAP column extraction.

windowSize = 10;                % Window size - this changes for every window size scenario.

sma = filter(ones(1, windowSize)/windowSize, 1, vwap);  % Simple moving average filter. (SMA for FIR filter)

alpha = 2 / (windowSize + 1);                           % Smoothing factor for EMA. Inversely correlated to window size.
ema = zeros(size(vwap));
ema(1) = vwap(1);                                       % Initialize EMA with first value

for i = 2:length(vwap)
    ema(i) = alpha * vwap(i) + (1 - alpha) * ema(i-1);  % Exponential moving average filter. (EMA for IIR filter)
end

figure;
plot(vwap(end-999:end), 'b'); hold on;              % Original data (last 1000 days)
plot(sma(end-999:end), 'r', 'LineWidth', 1.5);      % Original data with FIR filter (last 1000 days)
plot(ema(end-999:end), 'g', 'LineWidth', 1.5);      % Original data with IIR filter (last 1000 days)

ttl = title(strcat(current_file, ' - SMA vs EMA - Last 1000 Days'));
set(ttl, 'FontSize', 18)
xlabel('Days');
ylabel('VWAP');
leg = legend('Original Data', ...
             strcat('SMA with window size = ', int2str(windowSize)), ...
             strcat('EMA with alpha = ', num2str(alpha)));
set(leg, 'FontSize', 16);
grid on;
