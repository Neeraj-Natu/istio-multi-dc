package app;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@SpringBootApplication
@Slf4j
@EnableScheduling
public class App {
    private final WebClient client;

    public App(WebClient.Builder client) {
        this.client = client
                .baseUrl("http://default.service2.global")
                .build();
    }

    @Scheduled(fixedDelay = 1000L)
    public void query() {
        this.client
                .get()
                .uri("/call")
                .retrieve()
                .onStatus(HttpStatus::isError, resp -> Mono.just(new RuntimeException("bad status: " + resp.statusCode())))
                .bodyToMono(Integer.class)
                .subscribe(value -> log.info("Value: {}", value), err -> log.warn("Error: {}", err.getMessage()));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class);
    }
}

