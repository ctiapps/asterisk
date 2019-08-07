TODO
====

## AMI

- There should be only one receiver at the moment, receiver should be reworked.
References:

  - https://github.com/ctiapps/asterisk/blob/8e7cc1b55ce0df34b2a6f7fc3f469b9f79c3e75d/src/asterisk/ami.cr#L18
  - https://github.com/ctiapps/asterisk/blob/8e7cc1b55ce0df34b2a6f7fc3f469b9f79c3e75d/src/asterisk/ami.cr#L108-L109

- While callbacks are receiving instance of ami and able to invoke `send_action`
  method, method itself is not yet thread or spawn safe. It should be reworked.

  - https://github.com/ctiapps/asterisk/blob/8e7cc1b55ce0df34b2a6f7fc3f469b9f79c3e75d/src/asterisk/ami.cr#L106

- Add automatic reconnect support

- Add close reason

  - https://github.com/ctiapps/asterisk/blob/8e7cc1b55ce0df34b2a6f7fc3f469b9f79c3e75d/src/asterisk/ami.cr#L268

- Add support for actions that create multiple events in response (i.e.
  `SIPPeers`). That should also eliminate need of `expects_answer_before` in
  send_action and receiver.
