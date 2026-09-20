import { Icons } from "./ui";

const CUSTOMER_INFORMATION = [
  { title: "Báo giá", description: "Xem từng hạng mục, số lượng phụ tùng và chi phí trước khi xác nhận sửa chữa.", icon: Icons.fileText },
  { title: "Tiến độ sửa chữa", description: "Theo dõi trạng thái tiếp nhận, kiểm tra, sửa chữa và thời điểm bàn giao xe.", icon: Icons.wrench },
  { title: "Lịch sử dịch vụ", description: "Tra cứu các lần sửa chữa đã hoàn tất cùng nội dung thực hiện và tổng chi phí.", icon: Icons.history },
];

export default function PublicTestimonials() {
  return (
    <section aria-labelledby="homepage-customer-info-title" className="public-reveal bg-surface-subtle">
      <div className="mx-auto w-full max-w-7xl px-4 py-16 sm:px-6 sm:py-24">
        <div className="text-center">
          <p className="public-kicker text-accent">Khu vực khách hàng</p>
          <h2 id="homepage-customer-info-title" className="public-section-title mt-3 text-foreground">Thông tin cần thiết sau khi gửi xe.</h2>
        </div>
        <ul className="mt-9 grid grid-cols-1 gap-px overflow-hidden border border-border bg-border md:grid-cols-3">
          {CUSTOMER_INFORMATION.map((item) => (
            <li key={item.title} className="flex min-h-[230px] flex-col bg-white p-7 sm:p-8">
              <span className="grid h-11 w-11 place-items-center border border-border text-primary" aria-hidden="true">{item.icon}</span>
              <h3 className="mt-6 text-lg font-extrabold text-foreground">{item.title}</h3>
              <p className="mt-3 text-base leading-7 text-muted-foreground">{item.description}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
