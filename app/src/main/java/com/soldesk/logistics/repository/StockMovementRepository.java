package com.soldesk.logistics.repository;

import com.soldesk.logistics.domain.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.List;

public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {

    @Query("""
            SELECT m FROM StockMovement m
             JOIN FETCH m.product
             ORDER BY m.movementDate DESC
            """)
    List<StockMovement> findTop20ByOrderByMovementDateDesc(org.springframework.data.domain.Pageable pageable);

    default List<StockMovement> findTop20ByOrderByMovementDateDesc() {
        return findTop20ByOrderByMovementDateDesc(
                org.springframework.data.domain.PageRequest.of(0, 20));
    }

    @Query("""
            SELECT FUNCTION('DATE', m.movementDate) AS day,
                   m.movementType AS type,
                   SUM(m.quantity) AS total
              FROM StockMovement m
             WHERE m.movementDate >= :since
             GROUP BY FUNCTION('DATE', m.movementDate), m.movementType
             ORDER BY FUNCTION('DATE', m.movementDate) ASC
            """)
    List<Object[]> aggregateDailyMovement(java.time.LocalDateTime since);
}
