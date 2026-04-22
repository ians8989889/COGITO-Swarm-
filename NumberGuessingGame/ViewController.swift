import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var guessTextField: UITextField!
    @IBOutlet weak var attemptLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var playAgainButton: UIButton!

    var randomNumber: Int = 0
    var remainingAttempts: Int = 5

    override func viewDidLoad() {
        super.viewDidLoad()
        newGame()
    }

    func newGame() {
        randomNumber = Int(arc4random_uniform(100)) + 1
        remainingAttempts = 5
        instructionLabel.text = "猜數字遊戲！請輸入1-100之間的數字："
        guessTextField.text = ""
        resultLabel.text = ""
        attemptLabel.text = "剩餘次數：5"
        playAgainButton.isHidden = true
    }

    @IBAction func submitGuess(_ sender: UIButton) {
        guard let guessText = guessTextField.text, let guess = Int(guessText) else {
            resultLabel.text = "請輸入有效的數字"
            return
        }

        if guess < 1 || guess > 100 {
            resultLabel.text = "數字必須在1-100之間"
            return
        }

        remainingAttempts -= 1
        attemptLabel.text = "剩餘次數：$remainingAttempts"

        if guess == randomNumber {
            resultLabel.text = "恭喜！你猜中了！"
            playAgainButton.isHidden = false
        } else if guess < randomNumber {
            resultLabel.text = "太小了！"
        } else {
            resultLabel.text = "太大了！"
        }

        if remainingAttempts == 0 {
            resultLabel.text = "遊戲結束！正確答案是：$randomNumber"
            playAgainButton.isHidden = false
        }
    }

    @IBAction func playAgain(_ sender: UIButton) {
        newGame()
    }
}