import tingbot
from tingbot import screen

# setup code here
screen.fill(color='black')

def loop():
    # drawing code here
    screen.text('Hello world!')

# run the app
tingbot.run(loop)
