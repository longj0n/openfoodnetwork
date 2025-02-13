import { Controller } from "stimulus";

// Handles form elements for selecting previously saved Stripe cards from a list of cards

export default class extends Controller {
  static targets = ["stripeelements", "select"];

  connect() {
    this.selectCard(this.selectTarget.value);
  }

  onSelectCard(event) {
    this.selectCard(event.target.value);
  }

  selectCard(cardValue) {
    if (cardValue == "") {
      this.stripeelementsTarget.style.display = "block";
    } else {
      this.stripeelementsTarget.style.display = "none";
    }
  }
}
