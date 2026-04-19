package com.soldesk.logistics.controller;

import com.soldesk.logistics.domain.MovementType;
import com.soldesk.logistics.service.LogisticsService;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@Validated
public class DashboardController {

    private final LogisticsService logisticsService;

    public DashboardController(LogisticsService logisticsService) {
        this.logisticsService = logisticsService;
    }

    @GetMapping("/")
    public String dashboard(Model model) {
        model.addAttribute("products", logisticsService.getAllProducts());
        model.addAttribute("movements", logisticsService.getRecentMovements());
        model.addAttribute("chart", logisticsService.getDailyChartData(7));
        return "dashboard";
    }

    @PostMapping("/movements")
    public String createMovement(@RequestParam @NotNull Long productId,
                                 @RequestParam @NotNull MovementType movementType,
                                 @RequestParam @Positive int quantity,
                                 @RequestParam(required = false) String note,
                                 RedirectAttributes redirectAttributes) {
        try {
            logisticsService.recordMovement(productId, movementType, quantity, note);
            redirectAttributes.addFlashAttribute("flash", "입출고가 기록되었습니다.");
        } catch (RuntimeException ex) {
            redirectAttributes.addFlashAttribute("error", ex.getMessage());
        }
        return "redirect:/";
    }
}
