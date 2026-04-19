package com.soldesk.logistics.config;

import com.soldesk.logistics.domain.MovementType;
import com.soldesk.logistics.domain.Product;
import com.soldesk.logistics.domain.StockMovement;
import com.soldesk.logistics.repository.ProductRepository;
import com.soldesk.logistics.repository.StockMovementRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner seed(ProductRepository productRepository,
                           StockMovementRepository stockMovementRepository) {
        return args -> {
            if (productRepository.count() > 0) {
                return;
            }

            List<Product> products = List.of(
                    new Product("무선 키보드",       "전자기기",   120, "A-01"),
                    new Product("USB-C 케이블 1m",   "전자기기",   450, "A-03"),
                    new Product("노트북 거치대",     "전자기기",    85, "A-05"),
                    new Product("사무용 의자",       "가구",        35, "B-02"),
                    new Product("접이식 책상",       "가구",        22, "B-04"),
                    new Product("A4 복사용지",       "사무용품",   980, "C-01"),
                    new Product("볼펜 세트",         "사무용품",   310, "C-03"),
                    new Product("생수 500ml",        "식음료",     620, "D-04"),
                    new Product("커피 원두 1kg",     "식음료",      48, "D-06"),
                    new Product("방역 마스크",       "위생용품",    15, "E-02")
            );
            productRepository.saveAll(products);

            ThreadLocalRandom rand = ThreadLocalRandom.current();

            for (int day = 13; day >= 0; day--) {
                LocalDateTime base = LocalDateTime.now()
                        .minusDays(day)
                        .withHour(10).withMinute(0).withSecond(0).withNano(0);

                boolean weekend = base.getDayOfWeek() == DayOfWeek.SATURDAY
                        || base.getDayOfWeek() == DayOfWeek.SUNDAY;
                double volumeFactor = weekend ? 0.35 : 1.0;
                double peakFactor = (day <= 1) ? 1.6 : 1.0;

                for (Product product : products) {
                    int baseDemand = switch (product.getCategory()) {
                        case "사무용품", "식음료" -> 25;
                        case "전자기기" -> 15;
                        case "위생용품" -> 10;
                        case "가구" -> 3;
                        default -> 10;
                    };

                    int inQty = (int) Math.max(1,
                            baseDemand * volumeFactor * peakFactor * (0.7 + rand.nextDouble() * 0.6));
                    int outQty = (int) Math.max(1,
                            Math.max(1, baseDemand - 3) * volumeFactor * (0.6 + rand.nextDouble() * 0.8));

                    StockMovement inbound = new StockMovement(
                            product, MovementType.IN, inQty,
                            weekend ? "주말 입고" : "정기 입고");
                    inbound.setMovementDate(base.plusMinutes(rand.nextInt(0, 60)));
                    stockMovementRepository.save(inbound);

                    StockMovement outbound = new StockMovement(
                            product, MovementType.OUT, outQty, "주문 출고");
                    outbound.setMovementDate(base.plusHours(2).plusMinutes(rand.nextInt(0, 60)));
                    stockMovementRepository.save(outbound);
                }
            }
        };
    }
}
