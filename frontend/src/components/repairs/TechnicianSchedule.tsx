import { useState, useEffect } from 'react'
import { garageApi } from '../../api/garage'
import { errorMessage } from '../../api/client'
import { useGarageQuery } from '../../hooks/useGarageQuery'
import type { TechnicianWorkload } from '../../types/garage'
import { Button, Input, Select } from '../ui'
import { QueryState } from '../garage/QueryState'

export default function TechnicianSchedule({technicians,onSaved,onBusyChange}:{technicians:TechnicianWorkload[];onSaved:()=>void;onBusyChange:(busy:boolean)=>void}) {
  const shifts=useGarageQuery(garageApi.technicianShifts)
  const [id,setId]=useState('')
  const [date,setDate]=useState(()=>new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Ho_Chi_Minh'}).format(new Date()))
  const [selected,setSelected]=useState<number[]>([])
  const [limit,setLimit]=useState(2)
  const [busy,setBusy]=useState(false)
  const [message,setMessage]=useState('')
  const [shiftId,setShiftId]=useState('')
  const [name,setName]=useState('')
  const [start,setStart]=useState('')
  const [end,setEnd]=useState('')
  const [loadingSchedule,setLoadingSchedule]=useState(false)
  const [scheduleError,setScheduleError]=useState(false)
  useEffect(()=>{
    if(!id||!date)return
    const controller=new AbortController()
    setLoadingSchedule(true);setScheduleError(false)
    garageApi.technicianSchedule(date,controller.signal).then(rows=>{
      if(controller.signal.aborted)return
      const current=rows.find(t=>t.id===Number(id))
      setSelected(current?.shifts.map(s=>s.id)??[]);setLimit(current?.vehicleLimit??2)
    }).catch(e=>{if(!controller.signal.aborted){setMessage(errorMessage(e));setScheduleError(true)}})
      .finally(()=>{if(!controller.signal.aborted)setLoadingSchedule(false)})
    return ()=>controller.abort()
  },[id,date])
  async function save(action:()=>Promise<unknown>) {
    setBusy(true); onBusyChange(true); setMessage('')
    try { await action(); setMessage('Đã lưu thành công.'); shifts.reload(); onSaved() }
    catch(e) { setMessage(errorMessage(e,'Không lưu được lịch làm việc.')) }
    finally {setBusy(false);onBusyChange(false)}
  }
  return <details className="rounded border border-border p-3"><summary className="cursor-pointer font-medium">Quản lý ca làm và lịch nghỉ</summary>
    <QueryState loading={shifts.loading} error={shifts.error} onRetry={shifts.reload}/>
    <fieldset disabled={busy} className="mt-3 space-y-3">
      <Select label="Kỹ thuật viên cần xếp lịch" value={id} onChange={e=>{setId(e.target.value);const t=technicians.find(t=>t.id===Number(e.target.value));setLimit(t?.vehicleLimit??2);setSelected(t?.shifts.map(s=>s.id)??[])}} options={[{value:'',label:'Chọn kỹ thuật viên'},...technicians.map(t=>({value:String(t.id),label:t.fullName}))]}/>
      <Input label="Ngày làm việc" type="date" value={date} onChange={e=>{setDate(e.target.value);setSelected([])}}/>
      <Input label="Giới hạn xe đồng thời" type="number" min={1} max={100} value={limit} onChange={e=>setLimit(Number(e.target.value))}/>
      <p className="text-sm">Chọn ca cho ngày này. Không chọn ca nào nghĩa là nghỉ.</p>
      {shifts.data?.map(s=><label key={s.id} className="flex gap-2"><input type="checkbox" checked={selected.includes(s.id)} onChange={e=>setSelected(e.target.checked?[...selected,s.id]:selected.filter(x=>x!==s.id))}/>{s.name} ({s.start.slice(0,5)}–{s.end.slice(0,5)})</label>)}
      <Button type="button" disabled={loadingSchedule||scheduleError||!id||!date||!Number.isInteger(limit)||limit<1||limit>100||!!shifts.error||shifts.loading} onClick={()=>save(()=>garageApi.saveTechnicianSchedule(Number(id),{date,shiftIds:selected,vehicleLimit:limit}))}>{loadingSchedule?'Đang tải lịch…':'Lưu lịch ngày đã chọn'}</Button>
      <details><summary className="cursor-pointer">Cấu hình giờ ca làm</summary><div className="mt-3 space-y-3">
        <Select label="Ca làm" value={shiftId} options={[{value:'',label:'Tạo ca mới'},...(shifts.data??[]).map(s=>({value:String(s.id),label:s.name}))]} onChange={e=>{setShiftId(e.target.value);const s=shifts.data?.find(s=>s.id===Number(e.target.value));setName(s?.name??'');setStart(s?.start??'');setEnd(s?.end??'')}}/>
        <Input label="Tên ca" value={name} maxLength={100} onChange={e=>setName(e.target.value)}/>
        <Input label="Bắt đầu" type="time" value={start} onChange={e=>setStart(e.target.value)}/>
        <Input label="Kết thúc" type="time" value={end} onChange={e=>setEnd(e.target.value)}/>
        <Button type="button" disabled={!name.trim()||!start||!end||start>=end} onClick={()=>save(()=>garageApi.saveTechnicianShift(shiftId?Number(shiftId):null,{name:name.trim(),start,end}))}>Lưu ca làm</Button>
      </div></details>
    </fieldset><p role="status" className="mt-2 text-sm">{message}</p>
  </details>
}
