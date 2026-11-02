package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.ContactMessage;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface ContactMessageRepository extends JpaRepository<ContactMessage,Integer> {
    Optional<ContactMessage> findByRequestId(String requestId);
    @Modifying(clearAutomatically=true)
    @Query("update ContactMessage m set m.read=true where m.id=:id and m.read=false")
    int markRead(@Param("id") Integer id);
    @Modifying(clearAutomatically=true)
    @Query("update ContactMessage m set m.read=true where m.read=false")
    int markAllRead();
}
