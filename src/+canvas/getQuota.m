function [quota, status, resp] = getQuota(obj)

endpoint = "files/quota";
url = buildURL(obj, endpoint);

[quota, status, resp] = getPayload(obj, url);
if isempty(quota); return; end
quota = Chars2StringsRec(quota);

quota.quota_remaining = quota.quota - quota.quota_used;
quota.quota_used_percent = quota.quota_used / quota.quota;
quota.quota_remaining_percent = 1 - quota.quota_used_percent;
end
