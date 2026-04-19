package com.soldesk.logistics.config;

import com.soldesk.logistics.domain.MovementType;
import com.soldesk.logistics.domain.Product;
import com.soldesk.logistics.domain.StockMovement;
import com.soldesk.logistics.repository.ProductRepository;
import com.soldesk.logistics.repository.StockMovementRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Configuration
@Profile("dev")
public class DataInitializer {

    @Bean
    CommandLineRunner seed(ProductRepository productRepository,
                           StockMovementRepository stockMovementRepository) {
        return args -> {
            if (productRepository.count() > 0) {
                return;
            }

            List<Product> products = List.of(
                    new Product("무선 키보드", "전자기기", 120, "A-01"),
                    new Product("USB-C 케이블 1m", "전자기기", 450, "A-03"),
                    new Product("사무용 의자", "가구", 35, "B-02"),
                    new Product("A4 복사용지", "사무용품", 980, "C-01"),
                    new Product("생수 500ml", "식음료", 620, "D-04")
            );
            productRepository.saveAll(products);

            for (int day = 6; day >= 0; day--) {
                LocalDateTime base = LocalDateTime.now().minusDays(day).withHour(10).withMinute(0);
                for (Product product : products) {
                    int inQty = ThreadLocalRandom.current().nextInt(5, 40);
                    int outQty = ThreadLocalRandom.current().nextInt(1, Math.min(20, product.getQuantity()));

                    StockMovement inbound = new StockMovement(product, MovementType.IN, inQty, "정기 입고");
                    inbound.setMovementDate(base.plusMinutes(ThreadLocalRandom.current().nextInt(0, 60)));
                    stockMovementRepository.save(inbound);

                    StockMovement outbound = new StockMovement(product, MovementType.OUT, outQty, "주문 출고");
                    outbound.setMovementDate(base.plusHours(2).plusMinutes(ThreadLocalRandom.current().nextInt(0, 60)));
                    stockMovementRepository.save(outbound);
                }
            }
        };
    }
}
