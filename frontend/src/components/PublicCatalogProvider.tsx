import {createContext,useContext,type ReactNode} from "react";
import {publicCatalogApi,type PublicPart,type PublicService} from "../api/publicCatalog";
import {useGarageQuery} from "../hooks/useGarageQuery";
import {QueryState} from "./garage/QueryState";
const Context=createContext<{dichVu:PublicService[];phuTung:PublicPart[];ready:boolean}>({dichVu:[],phuTung:[],ready:false});
export const usePublicCatalog=()=>useContext(Context);
export default function PublicCatalogProvider({children}:{children:ReactNode}) {
  const query=useGarageQuery(publicCatalogApi.load);
  return <Context.Provider value={{dichVu:query.data?.services??[],phuTung:query.data?.parts??[],ready:!!query.data}}>
    {(query.loading||query.error)&&<div className="mx-auto max-w-6xl px-4"><QueryState {...query} onRetry={query.reload}/></div>}
    {children}
  </Context.Provider>;
}
