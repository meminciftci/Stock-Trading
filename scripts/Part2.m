file_names = {'HDFCBANK', 'ICICIBANK', 'INDUSINDBK', 'KOTAKBANK'};      % All datasets
log_all = {};           % Logs will be stored here  
cash = 10000;           % Our initial cash value
shares = containers.Map(file_names, {0, 0, 0, 0});      % Number of shares for each stock
prices = containers.Map();                              % Actual prices of shares

stock_data = struct();      % Prelocated memory for all the stock data

for s = 1:length(file_names)        % All the calculations are done here for every stock.
    name = file_names{s};           % Causality is preserved during the filtering processes. 
    data = readtable(strcat('../datasets/', name, '.csv'));
    vwap = data.VWAP;
    vwap = vwap(end-599:end);
    N = length(vwap);

    sma10 = movmean(vwap, [9 0]);   % Simple moving average with window size 10. (only past values)
    sma30 = movmean(vwap, [29 0]);  % Simple moving average with window size 30. (only past values)
    sma60 = movmean(vwap, [59 0]);  % Simple moving average with window size 60. (only past values)

    alpha10 = 2 / (10 + 1);
    alpha20 = 2 / (20 + 1);
    ema10 = zeros(N,1); ema20 = zeros(N,1);
    ema10(1) = vwap(1); ema20(1) = vwap(1);
    for i = 2:N
        ema10(i) = alpha10 * vwap(i) + (1 - alpha10) * ema10(i-1);      % Exponential moving average with alpha value 2/11.
        ema20(i) = alpha20 * vwap(i) + (1 - alpha20) * ema20(i-1);      % Exponential moving average with alpha value 2/21.
    end

    % Fused signal with different weights. We try to keep it as average as possible.
    fused_signal = 0.2 * sma10 + 0.3 * sma30 + 0.1 * sma60 + 0.2 * ema10 + 0.2 * ema20;

    % Vote calculation for decision making for whether to take actions.
    votes = zeros(N,1);
    votes = votes + (sma10 > [sma10(1); sma10(1:end-1)]);
    votes = votes + (sma30 > [sma30(1); sma30(1:end-1)]);
    votes = votes + (sma60 > [sma60(1); sma60(1:end-1)]);
    votes = votes + (ema10 > [ema10(1); ema10(1:end-1)]);
    votes = votes + (ema20 > [ema20(1); ema20(1:end-1)]);

    % All calculations go their respectful places on stock_data space.
    stock_data.(name).vwap = vwap;
    stock_data.(name).fused = fused_signal;
    stock_data.(name).votes = votes;
end

% For all the days (600 days), we are going to decide on buying and selling actions.
N = 600;
for day = 2:N
    trend_scores = containers.Map();        % Trend score is used for distributing buying actions.

    for s = 1:length(file_names)            % For every stock, trend strength is calculated.
        name = file_names{s};               % Trend strength decides the importance of that stock when buying it. 
        fused = stock_data.(name).fused;
        vwap = stock_data.(name).vwap;
        vote = stock_data.(name).votes(day);

        trend = fused(day) - fused(day - 1);    % Difference between today's expectation and yesterday's is trend.
        prices(name) = vwap(day);

        if trend > 0 && vote >= 4               % If trend is positive (increasing value) and vote is 4 or 5, enter here.
            rate = trend / fused(day - 1);      % With respect to rate of trend, choose a buying rate(x). 
            if rate > 0.005
                x = 0.25;
            elseif rate > 0.003
                x = 0.1;
            elseif rate > 0.002
                x = 0.05;
            else
                x = 0;
            end
            trend_scores(name) = x;
        else
            trend_scores(name) = 0;
        end
    end

    % Normalize scores
    total_score = sum(cell2mat(values(trend_scores)));
    if total_score > 0                  % With these calculations, higher trends get more cash values. 
        for s = 1:length(file_names)
            name = file_names{s};
            x = trend_scores(name);
            if x > 0
                allocation = (x / total_score) * cash;      % Allocated cash is proportional to x.
                if allocation > 1
                    p = prices(name);
                    num_shares = allocation / p;
                    shares(name) = shares(name) + num_shares;
                    cash = cash - allocation;
                    log_all{end+1} = sprintf('Day %d: BUY %.2f currency of %s', day, allocation, name);
                end
            end
        end
    end

    for s = 1:length(file_names)            % For selling, we again go over every stock.
        name = file_names{s};
        fused = stock_data.(name).fused;
        vote = stock_data.(name).votes(day);
        trend = fused(day) - fused(day - 1);

        if trend < 0 && vote <= 2 && shares(name) > 0       % This time, trend is negative (decline in value).
            rate = -trend / fused(day - 1);                 % Also vote value is 2, 1, or 0.
            if rate > 0.005                                 % We decide on selling rate by examining the rate of trend.
                x = 0.25;
            elseif rate > 0.003
                x = 0.1;
            elseif rate > 0.002
                x = 0.05;
            else
                x = 0;
            end
            if x > 0
                nsell = x * shares(name);                   % Final calculations for each stock. 
                amount = nsell * prices(name);              % This time we do not need to calculate trend score since
                if amount > 1                               % all selling actions happens in independent spaces.
                    shares(name) = shares(name) - nsell;
                    cash = cash + amount;
                    log_all{end+1} = sprintf('Day %d: SELL %.2f currency of %s', day, amount, name);
                end
            end
        end
    end
end

net_worth = cash;                   % Net worth consists of cash and money on every stock.
for s = 1:length(file_names)
    net_worth = net_worth + shares(file_names{s}) * prices(file_names{s});
end
fprintf('Final Net Worth After 600 Days: %.2f currency units\n', net_worth);

log_filename = strcat('trading_results_600_days.txt');          % Logging all the outputs to a txt file. 
fid = fopen(log_filename, 'w');
for i = 1:length(log_all)
    fprintf(fid, '%s\n', log_all{i});
end
fprintf(fid, 'Final Net Worth After 600 Days: %.2f currency units\n', net_worth);
fclose(fid);
