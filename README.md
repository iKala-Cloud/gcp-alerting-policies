# GCP Alerting Policies

使用前準備

1. 執行者必須具有 GCP 專案 owner 權限
2. GCP 專案必須已經關聯到 Stackdriver Workspace

使用步驟

1. Clone source repo to Cloud Shell
2. 在 Cloud Shell 執行以下指令

```
bash batch-apply.sh

# 依照畫面提示輸入 GCP Project ID
# 依照畫面提示輸入 SRE Team Email
# 依照畫面提示輸入 yes

# 依照畫面提示輸入 GCP Project ID (同上)
# 依照畫面提示輸入 yes
```

問題排除：如果遇到 `googleapi: Error 404` 就再執行一次 `bash batch-apply.sh`

執行結果

1. 建立 1 個 Notification Channel
2. 建立 9 個 Alerting Policy
    1. BQ over 1 GiB query event
    2. BQ scanned bytes billed over 1 TiB in 10 minutes
    3. GCE new instance event
    4. GCE vm egress bytes billed over 512 MiB in 10 minutes
    5. IAM set policy event
    6. PROJECT activate service event
    7. VPC new fwrule event
    8. Quota exceeded
    9. VPC service controls violation event
3. 建立 6 個 Log-based Metric
    1. user/user/bq/query/bigdata
    2. user/user/gce/instance/new
    3. user/user/iam/policy/set
    4. user/user/project/service/activate
    5. user/user/vpc/fwrule/new
	6. user/user/vpc/sc/violation
