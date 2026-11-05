import { useCallback,useEffect } from "react";
import { api,unwrap } from "../../api/client";
import type { ApiResponse } from "../../api/types";
import { useGarageQuery } from "../../hooks/useGarageQuery";
import { QueryState } from "../../components/garage/QueryState";
import { formatMoney } from "../../utils/garageFormat";
interface Share {garageAmount:number|null;total:number;approved:number|null;direct:boolean;customerAmount:number|null;settled:boolean;remaining:number|null}
export default function CustomerCoverage({id,total,onReady}:{id:number;total:number;onReady?:(ready:boolean)=>void}){
  const load=useCallback(async()=>unwrap(await api.get<ApiResponse<Share|null>>(`/api/customers/me/quotations/${id}/insurance`)),[id]);
  const query=useGarageQuery(load);
  useEffect(()=>onReady?.(!query.loading&&!query.error),[query.loading,query.error,onReady]);
  if(query.loading||query.error)return <QueryState {...query} onRetry={query.reload}/>;
  const s=query.data;
  if(!s)return <p>Khách thanh toán tại gara: {formatMoney(total)} · Không có hồ sơ bảo hiểm.</p>;
  return <div className="rounded-lg border p-3"><b>Bảo hiểm vật chất xe</b><p>Tổng chi phí sửa chữa: {formatMoney(s.total??total)}</p>
    {s.approved==null?<p>Đang chờ doanh nghiệp bảo hiểm duyệt. Phần khách thực trả chưa xác định.</p>:<><p>Bảo hiểm chấp thuận {formatMoney(s.approved)} · {s.direct?"trả cho gara":"hoàn trả cho khách"}</p>
    <p>Bảo hiểm trả trực tiếp cho gara: {formatMoney(s.garageAmount??(s.direct?s.approved:0))}</p><p>{s.settled?"Phần khách theo hóa đơn":"Phần khách dự kiến trả gara"}: {formatMoney(s.customerAmount??0)}</p>{s.remaining!=null&&<p>Còn phải trả: {formatMoney(s.remaining)}</p>}</>}
  </div>;
}
