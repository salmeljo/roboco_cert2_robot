from RPA.Robocloud.Secrets import Secrets

secrets = Secrets()
ORDER_PAGE = secrets.get_secret("robotorderpage")["url"]
