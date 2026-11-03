import { useCallback } from "react";
import { api,unwrap } from "../../api/client";
import type { ApiResponse } from "../../api/types";
import { useGarageQuery } from "../../hooks/useGarageQuery";
import { QueryState } from "../../components/garage/QueryState";
import { formatMoney } from "../../utils/garageFormat";
interface Share {approved:number|null;direct:boolean;customerAmount:number|null;settled:boolean;remaining:number|null}
export default function CustomerCoverage({id}:{id:number}){
  const load=useCallback(async()=>unwrap(await api.get<ApiResponse<Share|null>>(`/api/customers/me/quotations/${id}/insurance`)),[id]);
  const query=useGarageQuery(load);
  if(!query.data)return <QueryState {...query} onRetry={query.reload}/>;
  const s=query.data;
  return <div className="rounded-lg border p-3"><b>Bảo hiểm vật chất xe</b>
    {s.approved==null?<p>Đang chờ kết quả chi trả.</p>:<><p>Bảo hiểm chấp thuận {formatMoney(s.approved)} · {s.direct?"trả cho gara":"hoàn trả cho khách"}</p>
    <p>{s.settled?"Phần khách theo hóa đơn":"Phần khách dự kiến trả gara"}: {formatMoney(s.customerAmount??0)}</p>{s.remaining!=null&&<p>Còn phải trả: {formatMoney(s.remaining)}</p>}</>}
  </div>;
}
