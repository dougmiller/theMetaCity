from tmc import tmc

@tmc.route('/')
def root():
    return "This is only a test"
