const REVIEWS = [
  { quote: "Báo giá rõ từng hạng mục, tôi xác nhận trên hệ thống rồi gara mới làm. Rất yên tâm.", name: "Nguyễn Văn An", vehicle: "Toyota Vios" },
  { quote: "Tiến độ được cập nhật liên tục, không cần gọi hỏi nhiều lần mà vẫn biết xe đang ở bước nào.", name: "Trần Thị Bình", vehicle: "Honda City" },
  { quote: "Nhân viên giải thích dễ hiểu, thời gian bàn giao đúng hẹn và hóa đơn minh bạch.", name: "Lê Minh Cường", vehicle: "Ford Ranger" },
];

function Stars() {
  return (
    <span className="flex gap-1 text-accent" aria-label="5 trên 5 sao">
      {Array.from({ length: 5 }, (_, index) => (
        <svg key={index} width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="m12 2.7 2.8 5.7 6.3.9-4.6 4.4 1.1 6.3-5.6-3-5.6 3 1.1-6.3-4.6-4.4 6.3-.9L12 2.7Z" /></svg>
      ))}
    </span>
  );
}

export default function PublicTestimonials() {
  return (
    <section aria-labelledby="homepage-reviews-title" className="bg-surface-subtle">
      <div className="mx-auto w-full max-w-7xl px-4 py-16 sm:px-6 sm:py-24">
        <div className="text-center"><p className="public-kicker text-accent">Khách hàng nói gì</p><h2 id="homepage-reviews-title" className="public-section-title mt-3 text-foreground">Uy tín được đo bằng trải nghiệm thật.</h2></div>
        <div className="mt-9 grid grid-cols-1 gap-px overflow-hidden border border-border bg-border md:grid-cols-3">
          {REVIEWS.map((review) => (
            <figure key={review.name} className="flex min-h-[250px] flex-col bg-white p-7 sm:p-8">
              <Stars />
              <blockquote className="mt-6 text-base font-medium leading-7 text-foreground">“{review.quote}”</blockquote>
              <figcaption className="mt-auto border-t border-border pt-5"><p className="font-extrabold text-foreground">{review.name}</p><p className="mt-1 text-xs font-bold uppercase tracking-wider text-muted-foreground">{review.vehicle}</p></figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
