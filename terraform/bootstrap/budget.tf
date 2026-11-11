# Alerte de budget : un courriel dès que la dépense réelle ou prévue approche du plafond.
# Une alerte ne coupe rien : elle prévient. Le lab ne crée que des ressources gratuites,
# ce budget sert à détecter une erreur.

resource "aws_budgets_budget" "lab" {
  name         = "${var.project}-mensuel"
  budget_type  = "COST"
  limit_amount = var.budget_limit_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
  }
}
