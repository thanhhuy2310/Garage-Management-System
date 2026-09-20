import { Icons } from "./ui";

const STEPS = [
  { title: "Đặt lịch", description: "Chọn dịch vụ, ngày giờ phù hợp.", icon: Icons.calendar },
  { title: "Tiếp nhận xe", description: "Ghi nhận tình trạng và yêu cầu.", icon: Icons.inbox },
  { title: "Kiểm tra xe", description: "Chẩn đoán chi tiết bởi kỹ thuật viên.", icon: Icons.search },
  { title: "Báo giá", description: "Khách xác nhận trước khi thực hiện.", icon: Icons.fileText },
  { title: "Sửa chữa", description: "Đúng hạng mục, cập nhật tiến độ.", icon: Icons.wrench },
  { title: "Bàn giao", description: "Nghiệm thu, thanh toán, nhận xe.", icon: Icons.creditCard },
];

interface PublicProcessProps { onBook: () => void; }

export default function PublicProcess({ onBook }: PublicProcessProps) {
  return (
    <section aria-labelledby="homepage-process-title" className="bg-surface">
      <div className="mx-auto grid w-full max-w-7xl gap-10 px-4 py-16 sm:px-6 sm:py-24 lg:grid-cols-[0.8fr_1.2fr] lg:gap-16">
        <div className="lg:sticky lg:top-32 lg:self-start">
          <p className="public-kicker text-accent">Quy trình dịch vụ</p>
          <h2 id="homepage-process-title" className="public-section-title mt-3 text-foreground">6 bước rõ ràng.<br />Không có chi phí bất ngờ.</h2>
          <p className="mt-5 max-w-md text-sm leading-7 text-muted-foreground">Mỗi bước đều được lưu trên hệ thống. Khách hàng có thể theo dõi từ lúc đặt lịch đến khi nhận lại xe.</p>
          <button type="button" onClick={onBook} className="public-primary-button mt-7">Bắt đầu đặt lịch <span aria-hidden="true">→</span></button>
        </div>

        <ol className="border-t border-border">
          {STEPS.map((step, index) => (
            <li key={step.title} className="group grid grid-cols-[52px_1fr_auto] items-center gap-4 border-b border-border py-5 sm:grid-cols-[72px_1fr_auto] sm:py-6">
              <span className="mono text-2xl font-black text-border transition-all group-hover:text-accent sm:text-3xl" aria-hidden="true">{String(index + 1).padStart(2, "0")}</span>
              <div><h3 className="text-base font-extrabold uppercase tracking-tight text-foreground"><span className="sr-only">Bước {index + 1}: </span>{step.title}</h3><p className="mt-1 text-sm text-muted-foreground">{step.description}</p></div>
              <span className="grid h-11 w-11 place-items-center border border-border text-primary transition-all group-hover:border-primary group-hover:bg-primary group-hover:text-white" aria-hidden="true">{step.icon}</span>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
