CREATE TABLE "user_domain_subscriptions"
(
    "user_address" VARCHAR     NOT NULL,
    "domain_name"  VARCHAR     NOT NULL,
    "created_at"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY ("user_address", "domain_name"),
    FOREIGN KEY ("domain_name") REFERENCES "domains" ("name") ON DELETE CASCADE
);

CREATE INDEX idx_user_domain_subscriptions_user_address ON user_domain_subscriptions (user_address);
CREATE INDEX idx_user_domain_subscriptions_domain_name ON user_domain_subscriptions (domain_name);
