# Part E — So sánh Git Workflow

Trong phần này, em so sánh ba Git workflow phổ biến là **Trunk-based Development**, **GitFlow** và **GitHub Flow**.

| Tiêu chí | Trunk-based Development | GitFlow | GitHub Flow |
|---|---|---|---|
| **Số long-lived branch** | Thường chỉ có **1 branch chính** là `main` hoặc `trunk`. | Có **2 branch chính** là `main` và `develop`. | Thường chỉ có **1 branch chính** là `main`. |
| **Branch ngắn hạn** | Feature branch nếu có phải tồn tại rất ngắn, thường từ vài giờ đến một hoặc hai ngày. | Dùng `feature/*`, `release/*` và `hotfix/*`. Các branch có thể tồn tại trong suốt một chu kỳ release. | Mỗi feature hoặc bug fix có một branch riêng. Branch được xóa sau khi Pull Request đã merge. |
| **Luồng tích hợp code** | Developer tích hợp thường xuyên vào `main`; thay đổi lớn được chia thành nhiều phần nhỏ. | `feature/*` merge vào `develop`, sau đó qua `release/*` rồi mới merge vào `main`. | Branch mới được tạo từ `main`, sau đó mở Pull Request, review, chạy CI và merge lại `main`. |
| **Phù hợp scenario nào** | SaaS, web service, microservice hoặc team cần continuous delivery và deploy thường xuyên. | Mobile, desktop, on-premise hoặc sản phẩm phát hành theo version và cần giai đoạn QA/UAT riêng. | Web app, API, open-source project hoặc team dùng GitHub và muốn quy trình Pull Request đơn giản. |
| **Release cadence** | Nhanh nhất; có thể release nhiều lần trong ngày nếu pipeline thành công. | Theo kế hoạch như theo sprint, theo tháng hoặc theo version. | Linh hoạt; có thể release sau mỗi Pull Request hoặc gom nhiều PR thành một đợt release. |
| **Trạng thái `main`** | `main` phải luôn build được và ưu tiên luôn deployable. | `main` chứa code đã release; `develop` chứa code chuẩn bị cho release tiếp theo. | `main` phải luôn ổn định và có thể deploy. |
| **Cách xử lý feature chưa hoàn thiện** | Merge code nhỏ lên `main` nhưng ẩn bằng feature flag hoặc branch by abstraction. | Có thể giữ feature trên `feature/*` cho đến khi hoàn thành. | Có thể giữ trên branch ngắn hạn hoặc merge sau feature flag. |
| **Hotfix production** | Tạo bản sửa nhỏ, chạy CI, merge vào `main` và deploy ngay. | Tạo `hotfix/*` từ `main`, sau đó merge lại cả `main` và `develop`. | Tạo fix branch từ `main`, mở Pull Request, chạy CI rồi merge và deploy. |
| **Quản lý nhiều version** | Không phải điểm mạnh; cần bổ sung `release/*` hoặc `support/*` nếu phải duy trì nhiều version. | Hỗ trợ tốt nhất khi phải bảo trì nhiều version hoặc release line song song. | Không có quy trình mặc định; cần bổ sung release branch và version tag. |
| **Yêu cầu về CI/CD** | Rất cao: test phải nhanh, ổn định và chạy liên tục. | Trung bình đến cao: cần pipeline khác nhau cho `develop`, `release/*`, `main` và `hotfix/*`. | Trung bình đến cao: CI cần chạy trên Pull Request và sau khi merge vào `main`. |
| **Độ phức tạp** | Cấu trúc branch đơn giản nhưng yêu cầu kỹ thuật và kỷ luật tích hợp cao. | Phức tạp nhất vì có nhiều loại branch, nhiều bước merge và nhiều môi trường release. | Dễ hiểu hơn GitFlow, chủ yếu xoay quanh branch, Pull Request và `main`. |
| **Khó khăn khi áp dụng** | CI chậm hoặc test không ổn định sẽ ảnh hưởng cả team; cần quản lý feature flag và database migration cẩn thận. | Dễ conflict, lệch code giữa các branch hoặc quên merge hotfix ngược về `develop`. | PR tồn tại lâu sẽ lớn và khó review; `main` có thể hỏng nếu thiếu branch protection và required checks. |
| **Ưu điểm chính** | Feedback nhanh, conflict nhỏ, thay đổi nhỏ và phù hợp continuous deployment. | Quản lý version, release, QA/UAT và hotfix rõ ràng. | Quy trình đơn giản, dễ review, dễ audit và tích hợp tốt với GitHub Actions. |

## 1. Trunk-based Development

Với Trunk-based, các thành viên tích hợp code liên tục vào `main`. Nếu sử dụng feature branch thì branch này phải tồn tại trong thời gian ngắn và được merge sớm.

Ưu điểm:

- Phát hiện conflict và lỗi sớm.
- Thay đổi nhỏ nên dễ review và rollback.
- Phù hợp với continuous integration và continuous deployment.
- Có thể đưa tính năng lên production nhanh.

Hạn chế:

- Test tự động phải đủ tốt để bảo vệ `main`.
- Pipeline chậm sẽ làm ảnh hưởng tới cả team.
- Tính năng chưa hoàn thiện cần được ẩn bằng feature flag.
- Database migration cần tương thích với cả code cũ và code mới.

CI/CD có thể hoạt động như sau:

```text
Commit/Pull Request
        ↓
Lint + Unit Test + Security Scan
        ↓
Merge vào main
        ↓
Build Docker Image
        ↓
Deploy Staging
        ↓
Smoke Test
        ↓
Deploy Production
```

Artifact chỉ nên được build một lần. Ví dụ CI build image `app:<git-sha>`, sau đó cùng image này được promote từ staging lên production.

## 2. GitFlow

GitFlow sử dụng `main` để chứa code production và `develop` để tích hợp tính năng cho release tiếp theo.

Luồng branch cơ bản:

```text
feature/* → develop → release/* → main
                    ↘
main → hotfix/* → main + develop
```

Ưu điểm:

- Phân biệt rõ code development và code production.
- Có giai đoạn riêng để QA, UAT và sửa lỗi trước khi release.
- Dễ quản lý hotfix và nhiều version đang được hỗ trợ.

Hạn chế:

- Có nhiều branch nên workflow phức tạp.
- Phải merge code qua nhiều branch.
- Dễ quên merge hotfix từ `main` trở lại `develop`.
- Feature branch tồn tại lâu có thể tạo conflict lớn.

Cách kết hợp CI/CD:

| Branch | Pipeline đề xuất | Môi trường |
|---|---|---|
| `feature/*` | Lint, unit test, secret scan và build thử. | Local hoặc preview environment |
| `develop` | Integration test, contract test và deploy tự động. | Development/Integration |
| `release/*` | Regression test, E2E test, performance test và UAT. | Staging/UAT |
| `main` hoặc version tag | Promote artifact đã kiểm thử, tạo release note và deploy. | Production |
| `hotfix/*` | Chạy test liên quan, regression test tối thiểu và review khẩn cấp. | Staging rồi Production |

## 3. GitHub Flow

GitHub Flow có một branch dài hạn là `main`. Mỗi thay đổi được tạo trên branch riêng, sau đó mở Pull Request để review, chạy CI và merge lại `main`.

GitHub Flow vẫn có thể triển khai qua các môi trường **preview**, **staging** và **production**. Điểm cần phân biệt là:

- GitHub Flow mô tả cách quản lý branch và Pull Request.
- Staging/production thuộc deployment pipeline, không bắt buộc phải tương ứng với các branch riêng.
- GitHub Actions có thể dùng GitHub Environments để lưu secret theo môi trường, giới hạn branch được deploy và yêu cầu approval trước production.

```text
Tạo branch từ main
        ↓
Commit và push
        ↓
Mở Pull Request
        ↓
Lint + Test + Security Scan
        ↓
Deploy Preview (tùy chọn)
        ↓
Review và merge vào main
        ↓
Build artifact một lần
        ↓
Deploy Staging
        ↓
Smoke Test / E2E Test
        ↓
Approval (nếu có)
        ↓
Promote cùng artifact lên Production
```

Ví dụ với một web API bán hàng:

1. Developer tạo branch `feature/apply-coupon` từ `main`.
2. Pull Request chạy unit test, integration test, Gitleaks và build Docker image thử.
3. CI tạo preview environment để QA kiểm tra API áp mã giảm giá.
4. Sau khi reviewer approve và CI pass, PR được merge vào `main`.
5. Pipeline build image `shop-api:<git-sha>` và deploy image đó lên staging.
6. Staging pass smoke/E2E test thì production job chờ approval.
7. Sau khi được approve, cùng image digest được promote lên production.

Không nên build lại một image khác cho production vì artifact đã kiểm thử trên staging và artifact production có thể không còn giống nhau.

### Ưu điểm

- **Quy trình đơn giản và dễ học:** team chỉ cần nhớ một vòng lặp là tạo branch từ `main` → mở Pull Request → review/CI → merge. Không cần xác định lúc nào phải merge qua `develop`, `release/*` hoặc merge ngược hotfix như GitFlow. Ví dụ một bug fix nhỏ cũng đi qua đúng quy trình như một feature, nên người mới dễ làm đúng hơn.

- **Pull Request hỗ trợ review và lưu lại lịch sử quyết định:** reviewer nhìn thấy diff, comment trực tiếp trên từng dòng, yêu cầu thay đổi và kiểm tra kết quả CI trước khi approve. Sau này khi điều tra lỗi, team có thể mở lại PR để biết thay đổi được tạo vì issue nào, ai review và các check nào đã pass.

- **Kết hợp tự nhiên với GitHub Actions:** sự kiện `pull_request` có thể chạy test và tạo preview environment; sự kiện `push` vào `main` có thể build artifact và deploy staging. Production có thể dùng environment approval, secret riêng và giới hạn chỉ `main` hoặc version tag được deploy.

- **Phù hợp với web application và API release thường xuyên:** các hệ thống này thường chỉ cần duy trì một phiên bản production đang hoạt động. Khi một PR nhỏ được merge, team có thể deploy ngay thay vì chờ gom thành một release branch.

- **Phù hợp với open-source:** contributor có thể fork repo, tạo branch và gửi Pull Request mà không cần quyền push vào repository chính. Maintainer vẫn review và chạy CI theo cùng một quy trình.

- **Ít chi phí quản lý branch:** chỉ có `main` là long-lived branch nên giảm việc đồng bộ nhiều branch. Team dành nhiều thời gian hơn cho review, test và deployment thay vì xử lý merge giữa các nhánh dài hạn.

GitHub Flow không chỉ phù hợp với team nhỏ. Team lớn vẫn có thể sử dụng nếu có `CODEOWNERS`, required reviews, merge queue, automated tests và quyền deployment được phân tách rõ.

### Hạn chế

- **Pull Request lớn hoặc tồn tại lâu:** trong lúc branch phát triển, `main` tiếp tục thay đổi nên branch dễ conflict hoặc chạy trên context đã cũ. PR quá lớn cũng làm reviewer khó hiểu hết tác động. Cách giảm rủi ro là chia thay đổi thành PR nhỏ, cập nhật thường xuyên từ `main` và dùng feature flag cho tính năng chưa hoàn thiện.

- **`main` phụ thuộc nhiều vào chất lượng CI:** nếu test thiếu hoặc flaky test bị bỏ qua, code lỗi vẫn có thể merge và đi tới staging/production. Cần required status checks, branch protection, merge queue, smoke test và cơ chế rollback.

- **Không định nghĩa sẵn cách duy trì nhiều version:** ví dụ ứng dụng desktop phải hỗ trợ đồng thời `v1.x` và `v2.x` thì một `main` là chưa đủ để phát hành patch riêng cho `v1.x`. Team phải bổ sung `release/1.x`, support branch hoặc version tag; lúc này workflow trở thành mô hình kết hợp chứ không còn GitHub Flow tối giản.

- **Tính năng lớn dễ làm branch sống lâu:** nếu chỉ merge khi toàn bộ feature hoàn thành, branch sẽ ngày càng xa `main`. Team cần chia feature thành phần nhỏ, giữ backward compatibility và ẩn phần chưa sẵn sàng bằng feature flag.

- **Workflow không tự bảo đảm an toàn production:** GitHub Flow chỉ mô tả luồng cộng tác trên Git. Việc có staging, approval, canary, monitoring và rollback hay không phụ thuộc vào CD pipeline do team cấu hình.

- **Dễ nhầm branch với environment:** tạo riêng `staging` branch và `production` branch có thể làm code giữa hai môi trường bị lệch do phải merge/cherry-pick nhiều lần. Cách an toàn hơn là build artifact từ `main` một lần rồi promote cùng artifact qua staging và production.

### Ví dụ pipeline theo môi trường

| Sự kiện | Kiểm tra hoặc hành động | Môi trường |
|---|---|---|
| Push lên feature branch | Lint, unit test, secret scan | CI |
| Mở/cập nhật Pull Request | Integration test, build thử, preview deployment | Preview |
| Merge vào `main` | Build và publish artifact theo Git SHA | Artifact registry |
| Artifact được tạo | Deploy tự động, smoke test, E2E test | Staging |
| Staging pass | Chờ manual approval hoặc tự động theo policy | Production gate |
| Được approve | Promote đúng artifact đã chạy trên staging | Production |

Các rule nên cấu hình cho `main`:

- Không cho push trực tiếp.
- Yêu cầu ít nhất một reviewer approve.
- Yêu cầu CI thành công trước khi merge.
- Không cho force push.
- Dùng `CODEOWNERS` cho các phần code quan trọng.
- Dùng merge queue nếu nhiều PR được merge liên tục.
- Dùng environment approval trước khi deploy production.

## 4. Một số lưu ý khi kết hợp với CI/CD

Các workflow khác nhau về cách quản lý branch, nhưng vẫn nên áp dụng các nguyên tắc sau:

1. **Build once, deploy many**

   Chỉ build artifact một lần, sau đó dùng đúng artifact đó cho development, staging và production.

2. **Không lưu secret trong repository**

   Secret nên được lưu trong GitHub Secrets, Vault hoặc secret manager của cloud provider.

3. **Branch protection**

   Các branch quan trọng phải yêu cầu review và CI thành công trước khi merge.

4. **Security check**

   Pipeline nên có dependency scan, secret scan, SAST và container image scan.

5. **Rollback**

   Khi release lỗi, có thể deploy lại artifact cũ, tắt feature flag hoặc dùng `git revert`. Không nên `reset --hard` và force push trên branch dùng chung.

6. **Database migration**

   Migration cần backward-compatible. Không nên xóa column ngay trong cùng release vì code cũ có thể vẫn đang chạy.

## 5. Kết luận

Theo em, không có workflow nào phù hợp cho tất cả dự án:

- **Trunk-based** phù hợp khi team có CI/CD tốt và muốn deploy liên tục.
- **GitFlow** phù hợp khi sản phẩm release theo version và cần giai đoạn QA/UAT rõ ràng.
- **GitHub Flow** phù hợp với đa số web project sử dụng GitHub vì đơn giản và dễ kết hợp với Pull Request, branch protection và GitHub Actions.

Nếu bắt đầu một web project mới, em sẽ chọn **GitHub Flow**. Khi hệ thống CI/CD và test automation tốt hơn, team có thể rút ngắn thời gian sống của branch để tiến gần tới **Trunk-based Development**.
