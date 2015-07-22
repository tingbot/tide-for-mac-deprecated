import tingbot
from tingbot import screen

# setup code here

def loop():
    # drawing code here
    screen.fill(color='black')
    screen.text('Hello world!')

# run the app
tingbot.run(loop)
