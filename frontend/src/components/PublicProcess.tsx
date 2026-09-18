import { Icons } from "./ui";

// Đúng 6 bước nghiệp vụ đã chốt — không thêm/bớt bước.
const STEPS = [
  { title: "Đặt lịch", description: "Khách đặt lịch online, chọn dịch vụ, ngày giờ phù hợp.", icon: Icons.calendar },
  { title: "Tiếp nhận xe", description: "Ghi nhận tình trạng ban đầu và yêu cầu của khách.", icon: Icons.inbox },
  { title: "Kiểm tra xe", description: "Kỹ thuật viên kiểm tra, chẩn đoán chi tiết.", icon: Icons.search },
  { title: "Báo giá", description: "Báo giá minh bạch, khách xác nhận trước khi làm.", icon: Icons.fileText },
  { title: "Sửa chữa / Bảo dưỡng", description: "Thực hiện đúng hạng mục đã duyệt, cập nhật tiến độ.", icon: Icons.wrench },
  { title: "Thanh toán & Bàn giao", description: "Nghiệm thu, thanh toán và bàn giao xe.", icon: Icons.creditCard },
];

interface PublicProcessProps {
  onBook: () => void;
}

export default function PublicProcess({ onBook }: PublicProcessProps) {
  return (
    <section aria-labelledby="homepage-process-title" className="border-y border-border bg-surface-subtle">
      <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:py-20">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-bold uppercase tracking-widest text-accent">Quy trình dịch vụ</p>
          <h2 id="homepage-process-title" className="ui-page-title mt-2">
            6 bước rõ ràng, xe vào — xe ra đúng hẹn
          </h2>
          <p className="ui-secondary-text mt-2 text-sm">
            Mỗi bước đều được ghi nhận trên hệ thống, khách theo dõi được từ lúc đặt lịch đến khi bàn giao.
          </p>
        </div>

        <ol className="mt-10 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {STEPS.map((step, index) => (
            <li
              key={step.title}
              className="card-shadow relative rounded-lg border border-border bg-card p-5 text-card-foreground"
            >
              <div className="flex items-center justify-between">
                <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-soft text-primary" aria-hidden="true">
                  {step.icon}
                </span>
                <span className="mono text-3xl font-extrabold text-border" aria-hidden="true">
                  {String(index + 1).padStart(2, "0")}
                </span>
              </div>
              <h3 className="ui-card-title mt-4">
                <span className="sr-only">Bước {index + 1}: </span>
                {step.title}
              </h3>
              <p className="mt-1 text-sm leading-relaxed text-muted-foreground">{step.description}</p>
            </li>
          ))}
        </ol>

        <div className="mt-8 text-center">
          <button
            type="button"
            onClick={onBook}
            className="inline-flex min-h-11 items-center rounded-md border border-accent bg-accent px-6 text-sm font-bold text-accent-foreground transition-all hover:brightness-90"
          >
            Bắt đầu từ bước 1 — Đặt lịch ngay
          </button>
        </div>
      </div>
    </section>
  );
}
