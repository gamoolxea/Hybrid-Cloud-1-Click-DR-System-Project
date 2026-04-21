package com.soldesk.logistics.repository;

import com.soldesk.logistics.domain.Product;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {
}
