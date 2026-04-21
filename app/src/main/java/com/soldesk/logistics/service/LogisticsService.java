package com.soldesk.logistics.service;

import com.soldesk.logistics.domain.MovementType;
import com.soldesk.logistics.domain.Product;
import com.soldesk.logistics.domain.StockMovement;
import com.soldesk.logistics.repository.ProductRepository;
import com.soldesk.logistics.repository.StockMovementRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@Transactional(readOnly = true)
public class LogisticsService {

    private final ProductRepository productRepository;
    private final StockMovementRepository stockMovementRepository;

    public LogisticsService(ProductRepository productRepository,
                            StockMovementRepository stockMovementRepository) {
        this.productRepository = productRepository;
        this.stockMovementRepository = stockMovementRepository;
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public List<StockMovement> getRecentMovements() {
        return stockMovementRepository.findTop20ByOrderByMovementDateDesc();
    }

    public Map<String, Object> getDailyChartData(int days) {
        LocalDateTime since = LocalDate.now().minusDays(days - 1L).atStartOfDay();
        List<Object[]> rows = stockMovementRepository.aggregateDailyMovement(since);

        Map<LocalDate, long[]> daily = new LinkedHashMap<>();
        for (int i = 0; i < days; i++) {
            daily.put(LocalDate.now().minusDays(days - 1L - i), new long[]{0L, 0L});
        }

        for (Object[] row : rows) {
            LocalDate day = toLocalDate(row[0]);
            MovementType type = (MovementType) row[1];
            long total = ((Number) row[2]).longValue();
            long[] bucket = daily.get(day);
            if (bucket == null) {
                continue;
            }
            if (type == MovementType.IN) {
                bucket[0] = total;
            } else {
                bucket[1] = total;
            }
        }

        List<String> labels = new ArrayList<>();
        List<Long> inboundSeries = new ArrayList<>();
        List<Long> outboundSeries = new ArrayList<>();
        daily.forEach((day, bucket) -> {
            labels.add(day.toString());
            inboundSeries.add(bucket[0]);
            outboundSeries.add(bucket[1]);
        });

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("labels", labels);
        result.put("inbound", inboundSeries);
        result.put("outbound", outboundSeries);
        return result;
    }

    @Transactional
    public StockMovement recordMovement(Long productId, MovementType type, int quantity, String note) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new EntityNotFoundException("Product not found: " + productId));

        if (type == MovementType.OUT && product.getQuantity() < quantity) {
            throw new IllegalStateException("재고가 부족합니다. 현재 재고: " + product.getQuantity());
        }

        int delta = type == MovementType.IN ? quantity : -quantity;
        product.setQuantity(product.getQuantity() + delta);
        productRepository.save(product);

        return stockMovementRepository.save(new StockMovement(product, type, quantity, note));
    }

    private LocalDate toLocalDate(Object raw) {
        if (raw instanceof LocalDate localDate) {
            return localDate;
        }
        if (raw instanceof java.sql.Date sqlDate) {
            return sqlDate.toLocalDate();
        }
        return LocalDate.parse(raw.toString());
    }
}
