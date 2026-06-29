# Part D — Alert rules cho web app

## 1. Mục tiêu của alert

Alert không phải để báo mọi thứ đang thay đổi trong hệ thống.

Alert chỉ nên bắn khi có vấn đề cần con người xử lý hoặc cần kiểm tra ngay. Nếu hệ thống chỉ hơi dao động bình thường thì nên để dashboard quan sát, không nên biến thành alert.

Với một web app, ưu tiên 3 nhóm alert chính:

- Latency: app phản hồi chậm.
- Error rate: app trả nhiều lỗi.
- Saturation: tài nguyên gần đầy hoặc bị quá tải.

Ba nhóm này bám khá sát tình huống thực tế: user thấy chậm, user gặp lỗi, hoặc hệ thống sắp hết tài nguyên để phục vụ request.

---

## 2. Alert rule 1: High latency

Latency là thời gian app phản hồi request. Nếu latency tăng cao trong một thời gian đủ lâu, user sẽ thấy website/API bị chậm.

Ví dụ Prometheus rule:

```yaml
groups:
  - name: web-app-alerts
    rules:
      - alert: WebAppHighLatency
        expr: |
          histogram_quantile(
            0.95,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
          ) > 0.5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Web app latency cao"
          description: "P95 latency > 500ms trong 10 phút."
```

Giải thích:

- `http_request_duration_seconds_bucket`: metric histogram đo thời gian xử lý request.
- `rate(...[5m])`: lấy tốc độ request trong 5 phút gần nhất.
- `histogram_quantile(0.95, ...)`: lấy P95 latency, tức là 95% request nhanh hơn giá trị này.
- `> 0.5`: nếu P95 lớn hơn 0.5 giây thì coi là chậm.
- `for: 10m`: chỉ alert nếu tình trạng này kéo dài 10 phút, tránh bắn alert vì spike ngắn.

Vì sao dùng P95 thay vì average:

- Average có thể che mất request chậm.
- Ví dụ 95 request nhanh, 5 request rất chậm thì average nhìn vẫn có thể ổn.
- P95 phản ánh trải nghiệm của nhóm user bị chậm tốt hơn.

Khi alert này bắn, em sẽ kiểm tra:

- App có deploy version mới không.
- Database/API upstream có chậm không.
- CPU/memory của app có tăng không.
- Có traffic tăng bất thường không.

---

## 3. Alert rule 2: High error rate

Error rate là tỷ lệ request lỗi. Với web app, lỗi 5xx thường nghiêm trọng hơn 4xx vì 5xx là lỗi phía server.

Ví dụ Prometheus rule:

```yaml
groups:
  - name: web-app-alerts
    rules:
      - alert: WebAppHighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Web app error rate cao"
          description: "Tỷ lệ HTTP 5xx > 5% trong 5 phút."
```

Giải thích:

- `http_requests_total`: tổng số request.
- `status=~"5.."`: chỉ lấy HTTP status 500, 502, 503, 504...
- Tử số là số request lỗi 5xx.
- Mẫu số là tổng số request.
- `> 0.05`: nếu hơn 5% request bị lỗi thì alert.
- `for: 5m`: lỗi kéo dài 5 phút mới bắn alert.

Vì sao alert này quan trọng:

- 5xx thường nghĩa là user không dùng được chức năng.
- Có thể do app bug, database lỗi, service phụ thuộc chết, hoặc deploy sai config.
- Đây là alert nên xử lý nhanh hơn latency warning.

Khi alert này bắn, em sẽ kiểm tra:

- Log app để xem stack trace/lỗi cụ thể.
- Deployment gần nhất.
- Health check của database/cache/service phụ thuộc.
- Tỷ lệ lỗi theo endpoint, ví dụ `/login`, `/checkout`, `/api/orders`.

Lưu ý:

- Không nên alert mạnh với toàn bộ 4xx.
- 404/400 có thể do user/client gọi sai, bot scan, hoặc link cũ.
- Nếu 401/403 tăng bất thường thì có thể tạo alert riêng cho security, nhưng không nên gom chung với server error.

---

## 4. Alert rule 3: Saturation cao

Saturation nghĩa là tài nguyên đang gần đầy hoặc gần quá tải. Ví dụ CPU cao, memory gần hết, disk gần đầy, connection pool gần đầy.

Với host/container, em sẽ đặt alert disk hoặc memory vì đây là lỗi dễ gây downtime.

Ví dụ alert disk free thấp:

```yaml
groups:
  - name: host-alerts
    rules:
      - alert: HostDiskAlmostFull
        expr: |
          (
            node_filesystem_avail_bytes{mountpoint="/", fstype!~"tmpfs|overlay|squashfs"}
            /
            node_filesystem_size_bytes{mountpoint="/", fstype!~"tmpfs|overlay|squashfs"}
          ) < 0.15
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Disk sắp đầy"
          description: "Root filesystem còn dưới 15% dung lượng trống trong 15 phút."
```

Giải thích:

- `node_filesystem_avail_bytes`: dung lượng disk còn trống.
- `node_filesystem_size_bytes`: tổng dung lượng disk.
- Chia 2 metric này để ra phần trăm còn trống.
- `< 0.15`: còn dưới 15% thì cảnh báo.
- `for: 15m`: tránh alert nếu metric bị sai hoặc dao động ngắn.

Vì sao disk gần đầy nguy hiểm:

- App có thể không ghi được log.
- Database có thể dừng ghi dữ liệu.
- Deploy mới có thể fail do không đủ dung lượng pull image.
- Một số service có thể crash nếu không tạo được file tạm.

Một alert saturation khác có thể đặt là memory usage cao:

```yaml
- alert: HostHighMemoryUsage
  expr: |
    (
      1 -
      node_memory_MemAvailable_bytes
      /
      node_memory_MemTotal_bytes
    ) > 0.9
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Memory usage cao"
    description: "Memory usage > 90% trong 10 phút."
```

Khi saturation alert bắn, em sẽ kiểm tra:

- Container/process nào dùng nhiều tài nguyên.
- Log có tăng đột biến không.
- Disk có file tạm, image cũ, log cũ không.
- Traffic có tăng không.
- Có memory leak sau deploy không.

---

## 5. Noise alert là gì?

Noise alert là alert bắn ra nhưng không giúp mình hành động gì rõ ràng.

Ví dụ noise:

- CPU vượt 80% trong 10 giây rồi tự hết.
- Có 1 request 500 trong cả ngày cũng bắn alert.
- Một service dev/test tắt ban đêm cũng bắn alert như production.
- Alert bắn liên tục nhưng team chỉ ignore vì không ảnh hưởng user.
- Alert dựa trên metric kỹ thuật quá thấp-level nhưng không gắn với impact thật.

Hậu quả của noise:

- Người trực bị mệt vì quá nhiều cảnh báo.
- Team bắt đầu mute hoặc bỏ qua alert.
- Khi incident thật xảy ra thì dễ bị trôi trong đống alert giả.
- Mất niềm tin vào hệ thống monitoring.

Theo em, nếu một alert thường xuyên không cần ai xử lý thì nên sửa hoặc xóa.

---

## 6. Actionable alert là gì?

Actionable alert là alert bắn ra và người nhận biết cần làm gì tiếp theo.

Một alert tốt nên có:

- Vấn đề rõ ràng: lỗi gì đang xảy ra.
- Mức độ ảnh hưởng: warning hay critical.
- Điều kiện đủ ổn định: dùng `for` để tránh spike ngắn.
- Gắn với user impact hoặc rủi ro downtime.
- Có hướng xử lý: link dashboard, log query, runbook nếu có.

Ví dụ actionable:

```text
P95 latency của production API > 500ms trong 10 phút.
```

Alert này actionable vì:

- Biết service nào bị ảnh hưởng.
- Biết triệu chứng là latency.
- Biết ngưỡng cụ thể.
- Biết nó kéo dài đủ lâu.
- Có thể mở dashboard/log để debug tiếp.

Ví dụ chưa actionable:

```text
CPU high.
```

Alert này hơi mơ hồ vì:

- Không biết service nào.
- Không biết cao bao nhiêu.
- Không biết kéo dài bao lâu.
- Không biết có ảnh hưởng user không.
- Không có hướng xử lý tiếp.

---

## 7. Cách em phân biệt noise vs actionable

Em sẽ tự hỏi mấy câu:

1. Alert này có ảnh hưởng user hoặc có nguy cơ downtime không?
2. Khi alert bắn, người trực có biết phải làm gì không?
3. Alert có bắn do spike ngắn không?
4. Alert có bắn ở môi trường không quan trọng như dev/test không?
5. Alert này có từng bị ignore nhiều lần không?

Nếu câu trả lời là "không biết làm gì" hoặc "bắn nhiều nhưng không ai xử lý", thì nhiều khả năng đó là noise.

Nếu alert gắn với trải nghiệm user hoặc tài nguyên sắp cạn, có threshold rõ ràng, có thời gian `for`, có dashboard/log để kiểm tra tiếp, thì đó là actionable.

---

## 8. Tóm tắt

3 alert em sẽ đặt cho web app:

| Nhóm alert | Ví dụ rule | Lý do |
| :--- | :--- | :--- |
| Latency | P95 latency > 500ms trong 10 phút | User thấy app chậm |
| Error rate | HTTP 5xx > 5% trong 5 phút | User gặp lỗi thật |
| Saturation | Disk free < 15% trong 15 phút | Hệ thống có nguy cơ fail |

Alert tốt không phải là alert thật nhiều. Alert tốt là alert giúp team phát hiện vấn đề quan trọng và hành động nhanh.
