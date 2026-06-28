# Part A — Observability Notes

Observability là khả năng hiểu trạng thái bên trong của hệ thống thông qua dữ
liệu mà hệ thống phát ra. Ba loại dữ liệu thường gặp nhất là log, metric và
trace. Mỗi loại trả lời một nhóm câu hỏi khác nhau, vì vậy không nên xem chúng
như ba công cụ thay thế hoàn toàn cho nhau.

## 1. Phân biệt log, metric và trace

### 1.1. Log

Log là bản ghi về một sự kiện đã xảy ra tại một thời điểm cụ thể.

Ví dụ ứng dụng nhận request đăng nhập:

```json
{
  "timestamp": "2026-06-28T10:15:01Z",
  "level": "ERROR",
  "service": "auth-service",
  "message": "Login failed",
  "user_id": "user-123",
  "request_id": "req-abc",
  "reason": "invalid password"
}
```

Log trên cho biết:

- Sự kiện xảy ra lúc nào.
- Xảy ra ở service nào.
- Mức độ nghiêm trọng là `ERROR`.
- Request nào bị lỗi và nguyên nhân cụ thể.

Log phù hợp để trả lời các câu hỏi:

```text
Lỗi cụ thể là gì?
Request nào bị lỗi?
Ứng dụng đã làm gì trước khi crash?
Stack trace nằm ở đâu?
```

Ưu điểm:

- Có nhiều thông tin chi tiết về từng sự kiện.
- Hữu ích khi debug một lỗi cụ thể.
- Có thể lưu stack trace, request ID và thông tin nghiệp vụ.
- Structured log dạng JSON dễ tìm kiếm và phân tích hơn plain text.

Hạn chế:

- Số lượng log lớn sẽ tốn dung lượng và chi phí lưu trữ.
- Tìm kiếm trên lượng log lớn có thể chậm.
- Khó nhìn xu hướng tổng thể nếu chỉ đọc từng dòng log.
- Nếu ghi password, token hoặc dữ liệu cá nhân vào log thì có thể gây rò rỉ
  thông tin.

Theo em, log nên chứa đủ context để debug nhưng không được chứa secret. Các
trường như `request_id`, `trace_id`, `service` và `level` giúp tìm log dễ hơn.

### 1.2. Metric

Metric là giá trị số được đo theo thời gian. Metric thường được tổng hợp thay vì
lưu toàn bộ chi tiết của từng request.

Ví dụ:

```text
http_requests_total{method="GET",route="/login",status="200"} 15230
http_requests_total{method="POST",route="/login",status="500"} 12
node_memory_MemAvailable_bytes 4294967296
probe_success{instance="https://example.com"} 1
```

Mỗi metric thường gồm:

```text
Tên metric + labels + giá trị + timestamp
```

Ví dụ:

```text
Tên metric: http_requests_total
Labels: method="GET", route="/login", status="200"
Giá trị: 15230
```

Metric phù hợp để trả lời:

```text
CPU hiện tại là bao nhiêu?
Trong 5 phút có bao nhiêu request lỗi?
P95 latency có vượt 500 ms không?
Dung lượng disk còn bao nhiêu phần trăm?
```

Ưu điểm:

- Nhẹ hơn log và phù hợp để lưu dữ liệu dài hạn.
- Truy vấn nhanh để vẽ dashboard.
- Phù hợp làm alert.
- Dễ nhìn xu hướng và so sánh theo thời gian.

Hạn chế:

- Không giữ đầy đủ context của từng request.
- Biết error rate tăng nhưng chưa chắc biết request nào gây lỗi.
- Label thiết kế sai có thể gây cardinality explosion.

Ví dụ metric báo:

```text
Tỷ lệ HTTP 500 tăng từ 0.1% lên 8%.
```

Metric giúp phát hiện vấn đề, nhưng để biết lỗi cụ thể là `database timeout` hay
`invalid configuration`, em vẫn cần xem log hoặc trace.

### 1.3. Trace

Trace mô tả toàn bộ hành trình của một request khi request đi qua nhiều service.
Một trace gồm nhiều span, trong đó mỗi span đại diện cho một bước xử lý.

Ví dụ request checkout:

```text
Trace ID: trace-001

checkout-service                       820 ms
├── validate-cart                      20 ms
├── call inventory-service            80 ms
├── call payment-service              650 ms
│   └── call payment-provider         610 ms
└── save order to database             70 ms
```

Nhìn trace trên, em có thể thấy request mất `820 ms`, trong đó phần gọi payment
provider mất `610 ms`. Như vậy bottleneck nằm ở payment provider chứ không phải
database.

Trace phù hợp để trả lời:

```text
Request đã đi qua những service nào?
Bước nào chậm nhất?
Lỗi bắt đầu từ service nào?
Dependency nào đang gây timeout?
```

Ưu điểm:

- Thấy được luồng xử lý end-to-end.
- Hữu ích với microservices và distributed system.
- Xác định được bottleneck và dependency gây lỗi.
- Có thể liên kết với log thông qua `trace_id` và `span_id`.

Hạn chế:

- Instrumentation phức tạp hơn metric cơ bản.
- Lưu toàn bộ trace có thể tốn chi phí nên thường phải sampling.
- Nếu context propagation bị mất thì trace sẽ bị đứt đoạn.
- Trace không phù hợp để thay metric làm dashboard tổng quan dài hạn.

### 1.4. So sánh nhanh

| Tiêu chí | Log | Metric | Trace |
| :--- | :--- | :--- | :--- |
| Dữ liệu chính | Sự kiện dạng text/JSON | Giá trị số theo thời gian | Hành trình của request |
| Mức độ chi tiết | Cao | Thấp, đã tổng hợp | Cao theo từng request |
| Câu hỏi chính | Chuyện gì đã xảy ra? | Hệ thống đang tốt hay xấu? | Request chậm/lỗi ở bước nào? |
| Dùng cho dashboard | Có thể nhưng không tối ưu | Rất phù hợp | Không phải mục đích chính |
| Dùng cho alert | Có thể | Phù hợp nhất | Có thể nhưng ít phổ biến hơn |
| Debug lỗi cụ thể | Rất tốt | Hạn chế | Rất tốt với distributed system |
| Ví dụ tool | Loki, Elasticsearch | Prometheus, CloudWatch | Tempo, Jaeger, Zipkin |

### 1.5. Ví dụ kết hợp cả ba

Giả sử website checkout chậm:

```text
Metric:
  Phát hiện P95 latency tăng từ 300 ms lên 2 giây.

Trace:
  Cho thấy payment-service chiếm 1.6 giây.

Log:
  Cho biết payment-service đang retry vì upstream timeout.
```

Theo em, flow xử lý sự cố thường là:

```text
Alert từ metric
      ↓
Mở dashboard xác định phạm vi
      ↓
Xem trace tìm service/span chậm
      ↓
Xem log theo trace_id để biết lỗi cụ thể
```

## 2. Pull-based và Push-based

Pull và push mô tả bên nào chủ động truyền metric.

```text
Pull:
Monitoring server chủ động lấy dữ liệu từ target.

Push:
Ứng dụng hoặc agent chủ động gửi dữ liệu đến collector/server.
```

### 2.1. Pull-based với Prometheus

Prometheus thường hoạt động theo mô hình pull. Ứng dụng hoặc exporter mở một
HTTP endpoint, thường là `/metrics`, sau đó Prometheus gọi endpoint này theo
scrape interval.

```text
Prometheus
    │
    ├── GET node-exporter:9100/metrics
    ├── GET app:8080/metrics
    └── GET blackbox-exporter:9115/metrics
```

Ví dụ cấu hình:

```yaml
scrape_configs:
  - job_name: node-exporter
    scrape_interval: 15s
    static_configs:
      - targets:
          - node-exporter:9100
```

Ưu điểm:

- Prometheus kiểm soát tần suất scrape tại một nơi.
- Dễ biết target còn hoạt động hay không thông qua metric `up`.
- Target không cần biết địa chỉ của Prometheus.
- Thêm hoặc xóa Prometheus không cần sửa code ứng dụng.
- Dễ dùng service discovery để tìm target trong Kubernetes hoặc cloud.
- Nếu Prometheus tạm thời quá tải, target không phải tự retry gửi metric.

Hạn chế:

- Prometheus phải kết nối được đến endpoint của target.
- Khó scrape service nằm sau firewall, NAT hoặc mạng private khác.
- Job chạy quá ngắn có thể kết thúc trước lần scrape tiếp theo.
- Prometheus cần service discovery tốt khi target thay đổi liên tục.
- Endpoint `/metrics` phải được bảo vệ, không nên public tùy ý ra Internet.

Với batch job ngắn hạn, Prometheus có Pushgateway. Tuy nhiên Pushgateway không
nên được dùng như cách mặc định để mọi service push metric vì việc quản lý
lifecycle của metric và xóa metric cũ sẽ phức tạp hơn.

### 2.2. Push-based với StatsD

Với StatsD, ứng dụng chủ động gửi metric đến StatsD agent/server, thường qua UDP.

```text
Application
    │
    ├── increment request counter
    ├── record request latency
    └── send UDP packets
            ↓
          StatsD
```

Ví dụ dữ liệu StatsD:

```text
api.request.count:1|c
api.request.duration:245|ms
```

Ưu điểm:

- Ứng dụng không cần mở endpoint `/metrics`.
- UDP có overhead thấp và ứng dụng không phải chờ phản hồi.
- Phù hợp để gửi counter, timer thường xuyên.
- Có thể hoạt động khi collector được đặt gần ứng dụng dưới dạng agent.

Hạn chế:

- UDP không bảo đảm packet được giao thành công.
- Khi collector lỗi hoặc network nghẽn, metric có thể bị mất.
- Khó xác định service còn sống chỉ dựa vào việc nó ngừng push.
- Phải cấu hình địa chỉ collector cho application/agent.
- Nếu mọi instance push quá nhiều, collector có thể trở thành bottleneck.

### 2.3. Push-based với OpenTelemetry Collector

Ứng dụng được instrument bằng OpenTelemetry SDK có thể gửi metric, log và trace
qua OTLP đến OpenTelemetry Collector.

```text
Application
    │ OTLP gRPC/HTTP
    ▼
OpenTelemetry Collector
    ├── batch
    ├── retry
    ├── filter/redact
    └── export
          ├── Prometheus
          ├── Grafana Tempo
          ├── Loki
          └── vendor observability
```

Collector giúp application không phụ thuộc trực tiếp vào backend observability.
Nếu đổi từ backend A sang backend B, phần lớn thay đổi nằm ở collector thay vì
phải sửa tất cả ứng dụng.

Ưu điểm:

- Nhận được cả metric, log và trace.
- Hỗ trợ batch, retry, queue, filter và transform.
- Có thể gửi cùng dữ liệu đến nhiều backend.
- Phù hợp với mô hình agent trên host hoặc gateway tập trung.
- OTLP qua gRPC/HTTP đáng tin cậy hơn việc chỉ gửi UDP như StatsD.

Hạn chế:

- Collector là thêm một thành phần phải vận hành và monitor.
- Nếu gateway collector bị lỗi mà không có HA, telemetry có thể bị gián đoạn.
- Queue và retry dùng thêm CPU, RAM và disk.
- Cấu hình pipeline receiver/processor/exporter có thể khá phức tạp.

OpenTelemetry Collector không chỉ hỗ trợ push. Nó cũng có receiver có thể scrape
Prometheus endpoint. Vì vậy OpenTelemetry là framework linh hoạt, còn pull/push
là cách truyền dữ liệu cụ thể trong từng pipeline.

### 2.4. So sánh pull và push

| Tiêu chí | Pull-based | Push-based |
| :--- | :--- | :--- |
| Bên chủ động | Monitoring server | Application hoặc agent |
| Ví dụ | Prometheus scrape `/metrics` | StatsD, OTLP đến OTel Collector |
| Kiểm soát interval | Tập trung ở server | Phụ thuộc client/agent |
| Phát hiện target down | Dễ qua scrape failure và `up=0` | Khó phân biệt target down hay không có dữ liệu |
| Target sau firewall/NAT | Khó hơn | Dễ hơn nếu target được phép outbound |
| Short-lived job | Có thể bị bỏ lỡ | Phù hợp hơn |
| Backpressure | Prometheus tự kiểm soát scrape | Client/collector cần queue, retry hoặc drop |
| Cấu hình application | Chỉ cần expose endpoint | Cần biết collector/agent để gửi dữ liệu |

Trong thực tế có thể kết hợp cả hai:

```text
Application push OTLP
        ↓
OpenTelemetry Collector
        ↓ expose Prometheus metrics endpoint
Prometheus pull từ Collector
```

## 3. SLI, SLO và SLA

Ba khái niệm này liên quan với nhau nhưng không giống nhau:

```text
SLI = Chỉ số thực tế đang đo
SLO = Mục tiêu nội bộ muốn đạt
SLA = Cam kết chính thức với khách hàng
```

### 3.1. SLI — Service Level Indicator

SLI là chỉ số đo chất lượng thực tế của service.

Ví dụ availability SLI:

```text
Availability = successful requests / valid requests × 100%
```

Nếu trong 30 ngày có:

```text
1,000,000 valid requests
999,200 successful requests
```

thì:

```text
SLI availability = 999,200 / 1,000,000 × 100% = 99.92%
```

Một số SLI phổ biến:

- Availability: tỷ lệ request thành công.
- Latency: tỷ lệ request hoàn thành dưới một ngưỡng.
- Error rate: tỷ lệ request lỗi.
- Durability: tỷ lệ dữ liệu không bị mất.
- Freshness: dữ liệu có được cập nhật đúng thời hạn không.

SLI phải được định nghĩa rõ. Ví dụ cần nói cụ thể status code nào được coi là
thành công và request nào được đưa vào mẫu số. Thông thường lỗi do client như
một số HTTP `4xx` có thể được loại khỏi availability SLI, tùy đặc điểm service.

### 3.2. SLO — Service Level Objective

SLO là mục tiêu mà team đặt ra cho một SLI trong một khoảng thời gian.

Ví dụ:

```text
Trong cửa sổ 30 ngày:

- Availability phải đạt ít nhất 99.9%.
- 95% request phải có latency dưới 300 ms.
```

SLI là kết quả thực tế, còn SLO là mức mục tiêu:

```text
SLI hiện tại: 99.92%
SLO yêu cầu: 99.90%
Kết quả: đang đạt SLO
```

SLO giúp team quyết định khi nào nên ưu tiên feature và khi nào nên ưu tiên độ
ổn định.

Nếu SLO availability là `99.9%` trong 30 ngày thì error budget là `0.1%`, tương
đương khoảng `43 phút 12 giây` không khả dụng.

```text
Error budget = 100% - SLO
```

Nếu team tiêu hết error budget quá nhanh, team có thể tạm dừng release rủi ro và
tập trung sửa reliability.

### 3.3. SLA — Service Level Agreement

SLA là thỏa thuận chính thức giữa nhà cung cấp dịch vụ và khách hàng.

SLA thường có:

- Chỉ số và cách đo.
- Mức cam kết.
- Phạm vi áp dụng và trường hợp loại trừ.
- Cách báo cáo.
- Hình thức bồi thường hoặc service credit nếu vi phạm.

Ví dụ:

```text
Nhà cung cấp cam kết availability hàng tháng ít nhất 99.5%.
Nếu thấp hơn 99.5%, khách hàng được nhận 10% service credit.
```

SLO nội bộ thường nên chặt hơn SLA:

```text
SLO nội bộ: 99.9%
SLA với khách hàng: 99.5%
```

Khoảng cách này tạo vùng an toàn để team phát hiện và xử lý vấn đề trước khi vi
phạm cam kết hợp đồng.

### 3.4. Ví dụ đầy đủ

Với một web API:

```text
SLI:
  Tỷ lệ request hợp lệ trả về 2xx/3xx trong 30 ngày.

SLO:
  Ít nhất 99.9% request hợp lệ thành công trong 30 ngày.

SLA:
  Cam kết với khách hàng đạt 99.5% mỗi tháng.
  Nếu vi phạm, khách hàng nhận service credit.
```

Điểm em cần nhớ:

```text
SLI đo thực tế.
SLO đặt mục tiêu kỹ thuật.
SLA là cam kết có ảnh hưởng kinh doanh/hợp đồng.
```

## 4. Cardinality explosion

### 4.1. Cardinality là gì?

Trong Prometheus, mỗi tổ hợp label khác nhau tạo thành một time series riêng.

Ví dụ:

```text
http_requests_total{
  method="GET",
  route="/users",
  status="200"
}
```

Nếu metric có:

```text
5 method × 100 route × 10 status = 5,000 time series
```

Đó là cardinality của metric theo các label trên.

### 4.2. Cardinality explosion là gì?

Cardinality explosion xảy ra khi số lượng tổ hợp label tăng quá nhanh hoặc gần
như không có giới hạn.

Ví dụ xấu:

```text
http_requests_total{
  user_id="983421",
  request_id="req-f8ab...",
  url="/users/983421/orders/72618"
}
```

Các giá trị như `user_id`, `request_id` và URL chứa ID có thể có hàng triệu giá
trị khác nhau. Mỗi request có thể tạo ra một time series mới.

Ví dụ:

```text
5 method
× 100 route
× 10 status
× 1,000,000 user_id
= 5,000,000,000 time series
```

Prometheus không thể xử lý hiệu quả lượng time series như vậy trên một máy bình
thường.

### 4.3. Hậu quả

Cardinality quá cao có thể gây:

- Prometheus sử dụng rất nhiều RAM để quản lý active series.
- Tăng dung lượng disk và network I/O.
- Scrape và ingestion chậm.
- PromQL query chậm hoặc timeout.
- Dashboard Grafana tải lâu.
- Alert evaluation bị trễ.
- Prometheus có thể bị OOM kill hoặc crash.
- Chi phí observability tăng mạnh nếu dùng managed service tính tiền theo series.

Điều nguy hiểm là một label mới như `request_id` có thể được deploy rất nhanh,
nhưng chỉ sau một thời gian ngắn đã tạo ra hàng triệu series.

### 4.4. Cách phòng tránh

Không dùng các giá trị không giới hạn làm metric label:

```text
Không nên:
request_id, trace_id, user_id, email, session_id, timestamp, UUID

Có thể dùng:
method, status_code, service, environment, region, route đã chuẩn hóa
```

Chuẩn hóa route:

```text
Không nên:
/users/123
/users/456
/users/789

Nên:
/users/:id
```

Thông tin chi tiết như `request_id`, `user_id` nên đặt trong log hoặc trace thay
vì metric label.

Ngoài ra có thể:

- Review metric và label trước khi đưa lên production.
- Dùng allowlist cho các label được phép.
- Dùng `metric_relabel_configs` để drop metric/label không cần thiết trước khi
  Prometheus lưu trữ.
- Dùng OpenTelemetry Collector processor để filter attribute có cardinality cao.
- Theo dõi số active series và memory của chính Prometheus.
- Đặt giới hạn ingestion/cardinality ở hệ thống lưu trữ metric tập trung.

Recording rule có thể giúp query dashboard nhanh hơn bằng cách tạo metric đã
aggregate, nhưng không tự xóa cardinality của metric gốc. Muốn giảm chi phí
ingestion thì phải ngăn hoặc drop series cardinality cao trước khi lưu.

## Kết luận

Theo cách em hiểu:

```text
Metric giúp phát hiện hệ thống đang có vấn đề.
Trace giúp tìm request chậm/lỗi ở service nào.
Log giúp xem nguyên nhân cụ thể.

Prometheus chủ động pull metric từ target.
StatsD/OTLP thường để application chủ động push đến collector.

SLI là số đo, SLO là mục tiêu, SLA là cam kết.

Metric label phải có tập giá trị hữu hạn để tránh cardinality explosion.
```

## Reference

- Prometheus overview: https://prometheus.io/docs/introduction/overview/
- Prometheus metric and label model: https://prometheus.io/docs/concepts/data_model/
- Prometheus Pushgateway: https://prometheus.io/docs/practices/pushing/
- OpenTelemetry Collector: https://opentelemetry.io/docs/collector/
- Google SRE — Service Level Objectives: https://sre.google/sre-book/service-level-objectives/
- Grafana — Cardinality management: https://grafana.com/docs/grafana-cloud/cost-management-and-billing/analyze-costs/metrics-costs/client-side-filtering/
