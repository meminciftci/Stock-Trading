file_names = {'HDFCBANK', 'ICICIBANK', 'INDUSINDBK', 'KOTAKBANK'};      % All the datasets
current_file = file_names{4};                                           % Selecting dataset. Change this for every dataset.
data = readtable(strcat('../datasets/', current_file, '.csv'));         % Reading the csv file of dataset.
vwap = data.VWAP;

vwap = vwap(end-999:end);           % The last 1000 vwap values from the vwap column.
N = length(vwap);       

% The idea is to combine different FIR and IIR filters to achieve a more
% complex filter that provides clearer look to the future.
% 3 FIR filters and 2 IIR filters are used for this purpose.

sma10 = movmean(vwap, [9 0]);       % Computing average of 10 vwap value. (window size is 10 and it is causal)
sma30 = movmean(vwap, [29 0]);      % Computing average of 30 vwap value. (window size is 30 and it is causal)
sma60 = movmean(vwap, [59 0]);      % Computing average of 60 vwap value. (window size is 60 and it is causal)

alpha10 = 2 / (10 + 1);             % Alpha value with window size 10. (2 / 11)
alpha20 = 2 / (20 + 1);             % Alpha value with window size 20. (2 / 21)

ema10 = zeros(N,1);
ema20 = zeros(N,1);
ema10(1) = vwap(1);
ema20(1) = vwap(1);
for i = 2:N
    ema10(i) = alpha10 * vwap(i) + (1 - alpha10) * ema10(i-1);
    ema20(i) = alpha20 * vwap(i) + (1 - alpha20) * ema20(i-1);
end

% Weighted fusion of signals. Emphasis is put on long term filter, sma60.
w_sma10 = 0.2;
w_sma30 = 0.1;
w_sma60 = 0.3;
w_ema10 = 0.2;
w_ema20 = 0.2;

fused_signal = w_sma10 * sma10 + ...
               w_sma30 * sma30 + ...
               w_sma60 * sma60 + ...
               w_ema10 * ema10 + ...
               w_ema20 * ema20;

% Plotting the implemented graph with the original graph. (Last 1000 days)
figure;
plot(vwap, 'b'); hold on;
plot(fused_signal, 'r', 'LineWidth', 1.5);
ttl = title([current_file, ' - Fused Trend Signal (Weighted Average) - Last 1000 Days']);
set(ttl, 'FontSize', 18)
xlabel('Days'); ylabel('VWAP');
leg = legend('Original Data', 'Fused Trend Signal (Including FIR and IIR Filters)');
set(leg, 'FontSize', 18);
grid on;
