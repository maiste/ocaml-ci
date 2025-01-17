module Run_time = Ocaml_ci.Run_time
module Client = Ocaml_ci_api.Client

let version = "1.0"

type t = {
  version : string;
  status : string;
  created_at : string;
  finished_at : string;
  queued_for : string;
  ran_for : string;
  can_rebuild : bool;
  can_cancel : bool;
  variant : string;
}
[@@deriving yojson]

let from_status_info_run_time ~step_info ~run_time ~can_rebuild ~can_cancel =
  {
    version;
    status =
      Option.fold ~none:""
        ~some:(fun i -> Fmt.str "%a" Client.State.pp i.Client.outcome)
        step_info;
    created_at =
      Option.fold ~none:""
        ~some:(fun i -> Run_time.Duration.pp_readable_opt i.Client.queued_at)
        step_info;
    finished_at =
      Option.fold ~none:""
        ~some:(fun i -> Run_time.Duration.pp_readable_opt i.Client.finished_at)
        step_info;
    queued_for =
      Run_time.Duration.pp_opt
        (Option.map Run_time.TimeInfo.queued_for run_time);
    ran_for =
      Run_time.Duration.pp_opt (Option.map Run_time.TimeInfo.ran_for run_time);
    can_rebuild;
    can_cancel;
    variant =
      Option.fold ~none:""
        ~some:(fun i -> Fmt.str "%s" i.Client.variant)
        step_info;
  }

let from_status_info ~step_info ~build_created_at =
  let timestamps = Option.map Run_time.Timestamp.of_job_info step_info in
  let timestamps =
    match timestamps with
    | None ->
        Dream.log "Error - No step-info.";
        None
    | Some (Error e) ->
        Dream.log "Error - %s" e;
        None
    | Some (Ok t) -> Some t
  in
  let run_time =
    Option.map (Run_time.TimeInfo.of_timestamp ~build_created_at) timestamps
  in
  from_status_info_run_time ~step_info ~run_time ~can_rebuild:false
    ~can_cancel:false

let to_json t = Yojson.Safe.to_string @@ to_yojson t
