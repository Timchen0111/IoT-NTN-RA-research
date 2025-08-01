function utc_time = fix_utc(utc)
    % 修正 UTC 時間進位
    seconds = utc(6);
    utc(6) = mod(seconds, 60);
    carry = floor(seconds / 60);
    utc(5) = utc(5) + carry;
    carry = floor(utc(5) / 60);
    utc(5) = mod(utc(5), 60);
    utc(4) = utc(4) + carry;
    carry = floor(utc(4) / 24);
    utc(4) = mod(utc(4), 24);
    utc(3) = utc(3) + carry;
    % 簡化處理：假設不跨月
    utc_time = utc;
end